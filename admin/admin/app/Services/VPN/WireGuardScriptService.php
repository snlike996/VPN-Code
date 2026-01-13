<?php

namespace App\Services\VPN;

use Exception;
use Illuminate\Support\Facades\Log;

/**
 * Handles WireGuard configuration using the wireguard-install.sh script.
 * 
 * This service automates the interaction with the popular wireguard-install.sh
 * script (https://git.io/wireguard) to create and manage WireGuard clients.
 */
class WireGuardScriptService
{
    /**
     * SSH connection service instance.
     *
     * @var SSHConnectionService
     */
    private SSHConnectionService $ssh;
    
    /**
     * Path to the wireguard install script on VPS.
     *
     * @var string
     */
    private string $scriptPath = '/root/wireguard-install.sh';
    
    /**
     * URL to download the wireguard install script.
     *
     * @var string
     */
    private string $scriptUrl = 'https://git.io/wireguard';

    /**
     * Initialize with SSH connection.
     *
     * @param SSHConnectionService $ssh Connected SSH service
     */
    public function __construct(SSHConnectionService $ssh)
    {
        $this->ssh = $ssh;
    }

    /**
     * Check if WireGuard is installed on the VPS.
     *
     * @return bool True if installed
     */
    public function isWireGuardInstalled(): bool
    {
        $result = $this->ssh->execute('which wg 2>/dev/null');
        return !empty($result['output']);
    }
    public function isExpectInstalled(): bool
    {
        $result = $this->ssh->execute('which expect 2>/dev/null');
        return trim($result['output']) === 'yes';
    }

    /**
     * Check if the install script exists on VPS.
     *
     * @return bool True if script exists
     */
    public function scriptExists(): bool
    {
        $result = $this->ssh->execute("test -f {$this->scriptPath} && echo 'yes'");
        Log::info('Script exists output', ['output' => $result['output']]);
        return trim($result['output']) === 'yes';
    }

    /**
     * Download and run initial WireGuard setup.
     *
     * @throws Exception If installation fails
     * @return bool True on success
     */
    public function installWireGuard(): bool
    {
        Log::info('Installing WireGuard on VPS');

        $result = $this->ssh->execute(
            "wget {$this->scriptUrl} -O {$this->scriptPath} 2>&1",
            120
        );

        if ($result['exit_code'] !== 0 && strpos($result['output'], 'saved') === false) {
            throw new Exception('Failed to download WireGuard script: ' . $result['output']);
        }

        $this->ssh->execute("chmod +x {$this->scriptPath}");

        // Run initial setup with default values
        // Script asks: IPv4, IPv6, Port, Client name, DNS
        // We send newlines for defaults, then "initial_client" for name, then "1" for DNS (Cloudflare)
        $result = $this->ssh->execute(
            "echo -e '\n\n\ninitial_client\n1\n' | bash {$this->scriptPath} 2>&1",
            180
        );

        Log::info('WireGuard installation output', ['output' => substr($result['output'], -500)]);

        return true;
    }

    /**
     * Create a new client configuration.
     *
     * @param string $clientName Unique client name (no spaces, alphanumeric)
     * @throws Exception If creation fails
     * @return string Config file content
     */
    public function createClient(string $clientName): string
    {
        if (!$this->isExpectInstalled()) {
            $result = $this->ssh->execute("apt-get install expect -y");
            if ($result['exit_code'] !== 0) {
                throw new Exception('Failed to install Expect: ' . $result['output']);
            }
            // Log::info('Expect installation output', ['output' => substr($result['output'], -500)]);
        }
        // Sanitize client name
        $clientName = preg_replace('/[^a-zA-Z0-9_-]/', '_', $clientName);
        $clientName = substr($clientName, 0, 50);

        Log::info('Creating WireGuard client', ['client' => $clientName]);

        // Check if client already exists
        $checkResult = $this->ssh->execute("test -f /root/{$clientName}.conf && echo 'exists'");
        if (trim($checkResult['output']) === 'exists') {
            Log::warning('Client config already exists, reading existing', ['client' => $clientName]);
            return $this->getClientConfig($clientName);
        }

        $expectScript = "/tmp/wg_expect_" . uniqid() . ".exp";
        
        // Create expect script with exact prompt matching
        $expectScriptContent = <<<'EXPECT'
#!/usr/bin/expect -f
set timeout 90
set client_name [lindex $argv 0]

# Enable output for debugging
log_user 1

spawn bash /root/wireguard-install.sh

# Wait for "Select an option:" and then "Option: " prompt
expect {
    "Select an option:" {
        expect {
            "Option: " {
                send "1\r"
            }
            timeout {
                puts "ERROR: Timeout waiting for Option prompt"
                exit 1
            }
        }
    }
    timeout {
        puts "ERROR: Timeout waiting for 'Select an option:'"
        exit 1
    }
}

# Wait for "Provide a name for the client:" and then "Name: " prompt
expect {
    "Provide a name for the client:" {
        expect {
            "Name: " {
                send "$client_name\r"
            }
            timeout {
                puts "ERROR: Timeout waiting for Name prompt"
                exit 1
            }
        }
    }
    timeout {
        puts "ERROR: Timeout waiting for 'Provide a name for the client:'"
        exit 1
    }
}

# Wait for "Select a DNS server for the client:" and then "DNS server [1]: " prompt
expect {
    "Select a DNS server for the client:" {
        expect {
            -re "DNS server \\\[1\\\]: " {
                send "1\r"
            }
            timeout {
                puts "ERROR: Timeout waiting for DNS server prompt"
                exit 1
            }
        }
    }
    timeout {
        puts "ERROR: Timeout waiting for 'Select a DNS server for the client:'"
        exit 1
    }
}

# Wait for script to complete
expect {
    eof {
        puts "Script completed successfully"
    }
    timeout {
        puts "WARNING: Script may still be running"
    }
}

# Wait for the process to finish
catch wait result
set exit_code [lindex $result 3]
if {$exit_code != 0} {
    puts "ERROR: Script exited with code $exit_code"
}
exit $exit_code
EXPECT;

        // Create the expect script
        $createExpectCmd = sprintf(
            "cat > %s << 'EXPECTEOF'\n%s\nEXPECTEOF",
            $expectScript,
            $expectScriptContent
        );
        
        $this->ssh->execute($createExpectCmd);
        $this->ssh->execute("chmod +x {$expectScript}");
        
        // Log::info('Executing WireGuard client creation with expect', [
        //     'script' => $expectScript,
        //     'client' => $clientName
        // ]);
        
        // Run the expect script with client name as argument
        $clientNameEscaped = escapeshellarg($clientName);
        $result = $this->ssh->execute("expect {$expectScript} {$clientNameEscaped} 2>&1", 120);
        
        // Log::debug('Create client output', [
        //     'output' => $result['output'],
        //     'exit_code' => $result['exit_code']
        // ]);
        
        // Clean up
        $this->ssh->execute("rm -f {$expectScript}");

        if ($result['exit_code'] !== 0) {
            throw new Exception('Failed to create client. Script output: ' . substr($result['output'], -500));
        }

        // Wait for file to be written
        sleep(1);

        // Read the generated config
        $configResult = $this->ssh->execute("cat /root/{$clientName}.conf 2>/dev/null");
        Log::debug('Config result [root]', ['output' => $configResult['output']]);

        if (empty($configResult['output'])) {
            $configResult = $this->ssh->execute("cat /home/*/{$clientName}.conf 2>/dev/null");
        }

        if (empty($configResult['output'])) {
            // List files to debug
            $listResult = $this->ssh->execute("ls -la /root/*.conf 2>&1");
            Log::debug('Config files in /root', ['files' => $listResult['output']]);
            
            throw new Exception('Failed to create client config. Script output: ' . substr($result['output'], -500));
        }

        Log::info('WireGuard client created successfully', ['client' => $clientName]);

        return $configResult['output'];
    }

    /**
     * List all existing client configs on VPS.
     *
     * @return array List of client names
     */
    public function listClients(): array
    {
        $result = $this->ssh->execute("ls /root/*.conf 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/.conf$//'");
        
        if (empty($result['output'])) {
            return [];
        }

        return array_filter(explode("\n", trim($result['output'])));
    }

    /**
     * Get config content for existing client.
     *
     * @param string $clientName Client name
     * @throws Exception If client not found
     * @return string Config content
     */
    public function getClientConfig(string $clientName): string
    {
        $result = $this->ssh->execute("cat /root/{$clientName}.conf 2>/dev/null");

        if (empty($result['output'])) {
            throw new Exception("Client config not found: {$clientName}");
        }

        return $result['output'];
    }

    /**
     * Remove a client from WireGuard using interactive script.
     * 
     * The wireguard-install.sh script requires:
     * 1. Option "2" to remove a client
     * 2. Client index number (1-based from the displayed list)
     * 3. Confirmation "y" to proceed with removal
     *
     * @param string $clientName Client name to remove
     * @throws Exception If removal fails or client not found
     * @return bool True on success
     */
    public function removeClient(string $clientName): bool
    {
        Log::info('Removing WireGuard client', ['client' => $clientName]);

        // Step 1: Get list of clients from the script's perspective
        // The script lists clients from /etc/wireguard/wg0.conf, not from .conf files
        $clientIndex = $this->findClientIndex($clientName);
        
        if ($clientIndex === null) {
            throw new Exception("Client not found on server: {$clientName}");
        }

        Log::info('Found client at index', ['client' => $clientName, 'index' => $clientIndex]);

        // Step 2: Create expect script for interactive removal
        $expectScript = "/tmp/wg_remove_" . uniqid() . ".exp";
        
        // Prompts sequence for removal:
        // 1. "Select an option:" -> "Option: " -> send "2"
        // 2. "Select the client to remove:" -> "Client: " -> send client index
        // 3. "Confirm {clientName} removal? [y/N]:" -> send "y"
        $expectScriptContent = <<<'EXPECT'
#!/usr/bin/expect -f
set timeout 90
set client_index [lindex $argv 0]
set client_name [lindex $argv 1]

# Enable output for debugging
log_user 1

spawn bash /root/wireguard-install.sh

# Wait for "Select an option:" and then "Option: " prompt
expect {
    "Select an option:" {
        expect {
            "Option: " {
                send "2\r"
            }
            timeout {
                puts "ERROR: Timeout waiting for Option prompt"
                exit 1
            }
        }
    }
    timeout {
        puts "ERROR: Timeout waiting for 'Select an option:'"
        exit 1
    }
}

# Wait for "Select the client to remove:" and then "Client: " prompt
expect {
    "Select the client to remove:" {
        expect {
            "Client: " {
                send "$client_index\r"
            }
            timeout {
                puts "ERROR: Timeout waiting for Client prompt"
                exit 1
            }
        }
    }
    timeout {
        puts "ERROR: Timeout waiting for 'Select the client to remove:'"
        exit 1
    }
}

# Wait for confirmation prompt "Confirm {name} removal? [y/N]:"
expect {
    -re "Confirm .* removal\\?" {
        send "y\r"
    }
    timeout {
        puts "ERROR: Timeout waiting for confirmation prompt"
        exit 1
    }
}

# Wait for completion message
expect {
    "removed!" {
        puts "Client removed successfully"
    }
    eof {
        puts "Script completed"
    }
    timeout {
        puts "WARNING: Script may still be running"
    }
}

# Wait for the process to finish
catch wait result
set exit_code [lindex $result 3]
exit $exit_code
EXPECT;

        // Create the expect script
        $createExpectCmd = sprintf(
            "cat > %s << 'EXPECTEOF'\n%s\nEXPECTEOF",
            $expectScript,
            $expectScriptContent
        );
        
        $this->ssh->execute($createExpectCmd);
        $this->ssh->execute("chmod +x {$expectScript}");
        
        Log::info('Executing WireGuard client removal with expect', [
            'script' => $expectScript,
            'client' => $clientName,
            'index' => $clientIndex
        ]);
        
        // Run the expect script with client index and name as arguments
        $clientNameEscaped = escapeshellarg($clientName);
        $result = $this->ssh->execute("expect {$expectScript} {$clientIndex} {$clientNameEscaped} 2>&1", 120);
        
        // Log::debug('Remove client output', [
        //     'output' => $result['output'],
        //     'exit_code' => $result['exit_code']
        // ]);
        
        // Clean up expect script
        $this->ssh->execute("rm -f {$expectScript}");

        // Verify removal by checking if config file still exists
        $checkResult = $this->ssh->execute("test -f /root/{$clientName}.conf && echo 'exists' || echo 'removed'");
        $fileStatus = trim($checkResult['output']);
        
        if ($fileStatus === 'exists') {
            // Config file still exists, try to remove it manually
            $this->ssh->execute("rm -f /root/{$clientName}.conf");
            Log::warning('Config file was not removed by script, removed manually', ['client' => $clientName]);
        }

        // Check if the removal was mentioned in the output
        if (strpos($result['output'], 'removed!') !== false || $fileStatus === 'removed') {
            Log::info('WireGuard client removed successfully', ['client' => $clientName]);
            return true;
        }

        // If we get here, something may have gone wrong
        if ($result['exit_code'] !== 0) {
            throw new Exception('Failed to remove client. Script output: ' . substr($result['output'], -500));
        }

        return true;
    }

    /**
     * Find the index of a client in the WireGuard script's client list.
     * 
     * The script gets clients from /etc/wireguard/wg0.conf by parsing
     * the "# BEGIN_PEER" comments, not from .conf files in /root.
     *
     * @param string $clientName Client name to find
     * @return int|null 1-based index or null if not found
     */
    public function findClientIndex(string $clientName): ?int
    {
        // Method 1: Parse clients from wg0.conf (how the script does it)
        $result = $this->ssh->execute(
            "grep -oP '(?<=# BEGIN_PEER ).*' /etc/wireguard/wg0.conf 2>/dev/null"
        );
        
        $clients = array_filter(
            array_map('trim', explode("\n", $result['output']))
        );
        
        Log::debug('Found clients from wg0.conf', ['clients' => $clients]);
        
        // Find the client index (1-based for the script)
        $index = 1;
        foreach ($clients as $client) {
            if ($client === $clientName) {
                return $index;
            }
            $index++;
        }
        
        // Method 2: Fallback - check .conf files in /root
        $confResult = $this->ssh->execute(
            "ls /root/*.conf 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/.conf$//' | grep -n '^{$clientName}$' | cut -d: -f1"
        );
        
        if (!empty(trim($confResult['output']))) {
            return (int) trim($confResult['output']);
        }
        
        return null;
    }

    /**
     * Get the list of clients as displayed by the WireGuard script.
     * 
     * This parses /etc/wireguard/wg0.conf to get the same list
     * that the wireguard-install.sh script displays.
     *
     * @return array List of client names in script order
     */
    public function getScriptClientList(): array
    {
        $result = $this->ssh->execute(
            "grep -oP '(?<=# BEGIN_PEER ).*' /etc/wireguard/wg0.conf 2>/dev/null"
        );
        
        return array_filter(
            array_map('trim', explode("\n", $result['output']))
        );
    }

    /**
     * Parse config content to extract metadata.
     *
     * @param string $configContent Raw config file content
     * @return array Parsed metadata
     */
    public function parseConfig(string $configContent): array
    {
        $metadata = [
            'client_ip' => null,
            'dns' => null,
            'endpoint' => null,
            'private_key' => null,
            'server_public_key' => null,
            'preshared_key' => null,
        ];

        // Parse Address
        if (preg_match('/Address\s*=\s*(.+)/i', $configContent, $matches)) {
            $metadata['client_ip'] = trim($matches[1]);
        }

        // Parse DNS
        if (preg_match('/DNS\s*=\s*(.+)/i', $configContent, $matches)) {
            $metadata['dns'] = trim($matches[1]);
        }

        // Parse Endpoint
        if (preg_match('/Endpoint\s*=\s*(.+)/i', $configContent, $matches)) {
            $metadata['endpoint'] = trim($matches[1]);
        }

        // Parse PrivateKey (Interface section)
        if (preg_match('/\[Interface\].*?PrivateKey\s*=\s*(\S+)/is', $configContent, $matches)) {
            $metadata['private_key'] = trim($matches[1]);
        }

        // Parse PublicKey (Peer section)
        if (preg_match('/\[Peer\].*?PublicKey\s*=\s*(\S+)/is', $configContent, $matches)) {
            $metadata['server_public_key'] = trim($matches[1]);
        }

        // Parse PresharedKey if exists
        if (preg_match('/PresharedKey\s*=\s*(\S+)/i', $configContent, $matches)) {
            $metadata['preshared_key'] = trim($matches[1]);
        }

        return $metadata;
    }

    /**
     * Get WireGuard interface status from VPS.
     *
     * @return string Status output
     */
    public function getStatus(): string
    {
        $result = $this->ssh->execute('wg show 2>/dev/null || echo "WireGuard not running"');
        return $result['output'];
    }
}
