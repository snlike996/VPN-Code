<?php

namespace App\Services\VPN;

use App\Models\VpnConfig;
use Exception;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

/**
 * Orchestrates VPN config generation using wireguard-install.sh script.
 * 
 * This service handles the complete flow of generating a WireGuard VPN
 * configuration by connecting to a VPS via SSH and automating the
 * wireguard-install.sh script interaction.
 */
class VPNGeneratorService
{
    /**
     * Generate a new VPN configuration.
     *
     * @param array $serverCredentials VPS connection details
     * @param string $clientName Unique client identifier
     * @param int|null $userId User requesting the config (optional)
     * @param int $expirationDays Days until config expires (0 = never)
     * @throws Exception When generation fails
     * @return array Generated config details
     */
    public function generate(
        array $serverCredentials,
        string $clientName,
        ?int $userId = null,
        int $expirationDays = 30
    ): array {
        $ssh = null;

        try {
            // Step 1: Validate credentials
            $this->validateCredentials($serverCredentials);

            // Step 2: Generate unique client name
            $uniqueClientName = $this->generateUniqueClientName(substr($clientName, 0, 8));

            Log::info('Starting VPN generation', [
                'host' => $serverCredentials['host'],
                'client' => $uniqueClientName
            ]);

            // Step 3: Connect via SSH
            $ssh = $this->createSSHConnection($serverCredentials);
            $ssh->connect();

            // Step 4: Initialize WireGuard script service
            $wireguard = new WireGuardScriptService($ssh);

            // Step 5: Ensure WireGuard is installed
            $this->ensureWireGuardInstalled($ssh, $wireguard);

            // Step 6: Create client config using script
            $configContent = $wireguard->createClient($uniqueClientName);

            // Step 7: Parse the config for metadata
            // $metadata = $wireguard->parseConfig($configContent);

            // Step 8: Generate download token
            // $downloadToken = Str::random(32);
            // $expiresAt = $expirationDays > 0 ? now()->addDays($expirationDays) : null;

            // Step 9: Disconnect SSH
            $ssh->disconnect();

            Log::info('VPN config generated successfully', [
                'client' => $uniqueClientName
            ]);

            return [
                'success' => true,
                'client_name' => $uniqueClientName,
                // 'expires_at' => $expiresAt?->toIso8601String(),
                // 'metadata' => [
                //     'client_ip' => $metadata['client_ip'],
                //     'endpoint' => $metadata['endpoint'],
                //     'dns' => $metadata['dns'],
                //     'server_host' => $serverCredentials['host']
                // ],
                'config_content' => $configContent
            ];

        } catch (Exception $e) {
            Log::error('VPN generation failed', [
                'error' => $e->getMessage(),
                'host' => $serverCredentials['host'] ?? 'unknown',
                'client' => $clientName
            ]);

            $this->safeDisconnect($ssh);
            throw $e;
        }
    }

    /**
     * Remove a client from VPS WireGuard configuration.
     *
     * @param array $serverCredentials VPS connection details
     * @param string $clientName Client name to remove
     * @throws Exception When removal fails
     * @return array Removal result details
     */
    public function removeClient(array $serverCredentials, string $clientName): array
    {
        $ssh = null;

        try {
            // Step 1: Validate credentials
            $this->validateCredentials($serverCredentials);

            Log::info('Starting VPN client removal', [
                'host' => $serverCredentials['host'],
                'client' => $clientName
            ]);

            // Step 2: Connect via SSH
            $ssh = $this->createSSHConnection($serverCredentials);
            $ssh->connect();

            // Step 3: Initialize WireGuard script service
            $wireguard = new WireGuardScriptService($ssh);

            // Step 4: Check if WireGuard is installed
            if (!$wireguard->isWireGuardInstalled()) {
                throw new Exception('WireGuard is not installed on this server');
            }

            // Step 5: Get client list before removal for verification
            $clientsBefore = $wireguard->getScriptClientList();
            
            if (!in_array($clientName, $clientsBefore)) {
                throw new Exception("Client '{$clientName}' not found on server");
            }

            // Step 6: Remove client using script
            $wireguard->removeClient($clientName);

            // Step 7: Verify removal
            $clientsAfter = $wireguard->getScriptClientList();
            $removed = !in_array($clientName, $clientsAfter);

            // Step 8: Disconnect SSH
            $ssh->disconnect();

            Log::info('VPN client removal completed', [
                'client' => $clientName,
                'removed' => $removed
            ]);

            return [
                'success' => true,
                'message' => "Client '{$clientName}' removed successfully",
                'client_name' => $clientName,
                'server_host' => $serverCredentials['host'],
                'verified' => $removed,
                'remaining_clients' => count($clientsAfter)
            ];

        } catch (Exception $e) {
            Log::error('VPN client removal failed', [
                'error' => $e->getMessage(),
                'host' => $serverCredentials['host'] ?? 'unknown',
                'client' => $clientName
            ]);

            $this->safeDisconnect($ssh);
            throw $e;
        }
    }

    /**
     * Get existing client config from VPS.
     *
     * @param array $serverCredentials VPS connection details
     * @param string $clientName Client name to retrieve
     * @throws Exception When retrieval fails
     * @return array Config details
     */
    public function getExistingConfig(array $serverCredentials, string $clientName): array
    {
        $ssh = null;

        try {
            $this->validateCredentials($serverCredentials);

            $ssh = $this->createSSHConnection($serverCredentials);
            $ssh->connect();

            $wireguard = new WireGuardScriptService($ssh);
            $configContent = $wireguard->getClientConfig($clientName);
            $metadata = $wireguard->parseConfig($configContent);

            $ssh->disconnect();

            return [
                'success' => true,
                'client_name' => $clientName,
                'config_content' => $configContent,
                'metadata' => $metadata
            ];

        } catch (Exception $e) {
            $this->safeDisconnect($ssh);
            throw $e;
        }
    }

    /**
     * List all clients on VPS.
     *
     * @param array $serverCredentials VPS connection details
     * @throws Exception When listing fails
     * @return array List of client names
     */
    public function listVPSClients(array $serverCredentials): array
    {
        $ssh = null;

        try {
            $this->validateCredentials($serverCredentials);

            $ssh = $this->createSSHConnection($serverCredentials);
            $ssh->connect();

            $wireguard = new WireGuardScriptService($ssh);
            $clients = $wireguard->listClients();
            $status = $wireguard->getStatus();

            $ssh->disconnect();

            return [
                'success' => true,
                'clients' => $clients,
                'count' => count($clients),
                'wireguard_status' => $status
            ];

        } catch (Exception $e) {
            $this->safeDisconnect($ssh);
            throw $e;
        }
    }

    /**
     * Test SSH connection to VPS.
     *
     * @param array $serverCredentials VPS connection details
     * @return array Connection test result
     */
    public function testConnection(array $serverCredentials): array
    {
        $ssh = null;

        try {
            $this->validateCredentials($serverCredentials);

            $ssh = $this->createSSHConnection($serverCredentials);
            $ssh->connect();

            // Test basic command
            $result = $ssh->execute('echo "Connection successful" && uname -a');
            
            // Check if WireGuard is installed
            $wgCheck = $ssh->execute('which wg 2>/dev/null && wg --version 2>/dev/null');

            $ssh->disconnect();

            return [
                'success' => true,
                'message' => 'SSH connection successful',
                'system_info' => $result['output'],
                'wireguard_installed' => !empty($wgCheck['output']),
                'wireguard_info' => $wgCheck['output'] ?: 'Not installed'
            ];

        } catch (Exception $e) {
            $this->safeDisconnect($ssh);

            return [
                'success' => false,
                'message' => 'SSH connection failed',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Create SSH connection service instance.
     *
     * @param array $credentials Server credentials
     * @return SSHConnectionService SSH service instance
     */
    private function createSSHConnection(array $credentials): SSHConnectionService
    {
        return new SSHConnectionService(
            host: $credentials['host'],
            username: $credentials['username'],
            password: $credentials['password'] ?? null,
            privateKey: $credentials['private_key'] ?? null,
            port: $credentials['port'] ?? 22
        );
    }

    /**
     * Ensure WireGuard is installed on the server.
     *
     * @param SSHConnectionService $ssh SSH connection
     * @param WireGuardScriptService $wireguard WireGuard service
     * @throws Exception If installation fails
     * @return void
     */
    private function ensureWireGuardInstalled(SSHConnectionService $ssh, WireGuardScriptService $wireguard): void
    {
        if (!$wireguard->isWireGuardInstalled()) {
            Log::info('WireGuard not installed, installing...');
            $wireguard->installWireGuard();
        } elseif (!$wireguard->scriptExists()) {
            Log::info('Downloading WireGuard script...');
            $ssh->execute('wget https://git.io/wireguard -O /root/wireguard-install.sh && chmod +x /root/wireguard-install.sh', 120);
        }
    }

    /**
     * Safely disconnect SSH if connected.
     *
     * @param SSHConnectionService|null $ssh SSH connection or null
     * @return void
     */
    private function safeDisconnect(?SSHConnectionService $ssh): void
    {
        if ($ssh && $ssh->isConnected()) {
            $ssh->disconnect();
        }
    }

    /**
     * Validate server credentials.
     *
     * @param array $credentials Credentials to validate
     * @throws Exception If validation fails
     * @return void
     */
    private function validateCredentials(array $credentials): void
    {
        if (empty($credentials['host'])) {
            throw new Exception('Server host is required');
        }

        if (empty($credentials['username'])) {
            throw new Exception('SSH username is required');
        }

        if (empty($credentials['password']) && empty($credentials['private_key'])) {
            throw new Exception('Either password or private key is required');
        }
    }

    /**
     * Generate unique client name.
     *
     * @param string $baseName Base name from user
     * @return string Unique client name
     */
    private function generateUniqueClientName(string $baseName): string
    {
        $sanitized = preg_replace('/[^a-zA-Z0-9]/', '_', $baseName);
        $sanitized = substr($sanitized, 0, 30);
        $random = substr(str_shuffle(str_repeat('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 10)), 0, 7);
        
        return "{$sanitized}_{$random}";
    }
}
