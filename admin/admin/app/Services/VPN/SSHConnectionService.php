<?php

namespace App\Services\VPN;

use phpseclib3\Net\SSH2;
use phpseclib3\Crypt\PublicKeyLoader;
use Exception;
use Illuminate\Support\Facades\Log;

/**
 * Handles SSH connections to VPS servers for WireGuard management.
 * 
 * This service establishes SSH connections using either password
 * or key-based authentication via the phpseclib library.
 */
class SSHConnectionService
{
    /**
     * SSH connection instance.
     *
     * @var SSH2|null
     */
    private ?SSH2 $connection = null;
    
    /**
     * VPS hostname or IP address.
     *
     * @var string
     */
    private string $host;
    
    /**
     * SSH port number.
     *
     * @var int
     */
    private int $port;
    
    /**
     * SSH username.
     *
     * @var string
     */
    private string $username;
    
    /**
     * SSH password (if using password auth).
     *
     * @var string|null
     */
    private ?string $password;
    
    /**
     * SSH private key content (if using key auth).
     *
     * @var string|null
     */
    private ?string $privateKey;

    /**
     * Initialize SSH connection parameters.
     *
     * @param string $host VPS hostname or IP address
     * @param string $username SSH username
     * @param string|null $password SSH password (if using password auth)
     * @param string|null $privateKey SSH private key content (if using key auth)
     * @param int $port SSH port number
     */
    public function __construct(
        string $host,
        string $username,
        ?string $password = null,
        ?string $privateKey = null,
        int $port = 22
    ) {
        $this->host = $host;
        $this->port = $port;
        $this->username = $username;
        $this->password = $password;
        $this->privateKey = $privateKey;
    }

    /**
     * Establish SSH connection to the VPS.
     *
     * @throws Exception When connection or authentication fails
     * @return bool True if connection successful
     */
    public function connect(): bool
    {
        try {
            $this->connection = new SSH2($this->host, $this->port);
            $this->connection->setTimeout(60);
            
            if ($this->privateKey) {
                $key = PublicKeyLoader::load($this->privateKey);
                
                if (!$this->connection->login($this->username, $key)) {
                    throw new Exception('SSH key authentication failed');
                }
            } elseif ($this->password) {
                if (!$this->connection->login($this->username, $this->password)) {
                    throw new Exception('SSH password authentication failed');
                }
            } else {
                throw new Exception('No authentication method provided');
            }

            Log::info('SSH connection established', [
                'host' => $this->host,
                'username' => $this->username
            ]);

            return true;

        } catch (Exception $e) {
            Log::error('SSH connection failed', [
                'host' => $this->host,
                'error' => $e->getMessage()
            ]);
            throw $e;
        }
    }

    /**
     * Execute a command on the remote server.
     *
     * @param string $command Command to execute
     * @param int $timeout Command timeout in seconds
     * @throws Exception When not connected or command fails
     * @return array{output: string, exit_code: int}
     */
    public function execute(string $command, int $timeout = 30): array
    {
        if (!$this->connection) {
            throw new Exception('SSH not connected. Call connect() first.');
        }

        $this->connection->setTimeout($timeout);
        $output = $this->connection->exec($command);
        $exitCode = $this->connection->getExitStatus();

        Log::debug('SSH command executed', [
            'command' => $command,
            'exit_code' => $exitCode,
            'output_length' => strlen($output)
        ]);

        return [
            'output' => trim($output),
            'exit_code' => $exitCode ?? 0
        ];
    }

    /**
     * Disconnect from the SSH session.
     *
     * @return void
     */
    public function disconnect(): void
    {
        if ($this->connection) {
            $this->connection->disconnect();
            $this->connection = null;
            
            Log::info('SSH connection closed', ['host' => $this->host]);
        }
    }

    /**
     * Check if currently connected.
     *
     * @return bool
     */
    public function isConnected(): bool
    {
        return $this->connection !== null && $this->connection->isConnected();
    }

    /**
     * Get the host address.
     *
     * @return string
     */
    public function getHost(): string
    {
        return $this->host;
    }
}
