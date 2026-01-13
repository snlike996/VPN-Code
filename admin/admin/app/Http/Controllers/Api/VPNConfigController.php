<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VpnConfig;
use App\Models\Wireguard;
use App\Services\VPN\VPNGeneratorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Exception;

/**
 * Handles VPN configuration generation API endpoints.
 * 
 * This controller provides REST API endpoints for generating,
 * removing, and managing VPN configurations. Currently supports
 * WireGuard protocol with extensibility for future protocols.
 */
class VPNConfigController extends Controller
{
    /**
     * The VPN generator service instance.
     *
     * @var VPNGeneratorService
     */
    protected VPNGeneratorService $vpnGenerator;

    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
        $this->vpnGenerator = new VPNGeneratorService();
    }
    
    public function generate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'client_name' => 'required|string|max:50|alpha_dash',
            'server_id' => 'required|integer|exists:wireguards,id',
            'protocol' => 'required|string|in:wireguard',
        ]);

        try {
            // Retrieve server configuration from database
            $server = $this->getServerByProtocol(
                $validated['server_id'],
                $validated['protocol']
            );

            if (!$server) {
                return response()->json([
                    'success' => false,
                    'error' => 'Server not found or inactive'
                ], 404);
            }

            // Validate server has required credentials
            $credentialError = $this->validateServerCredentials($server);
            if ($credentialError) {
                return response()->json([
                    'success' => false,
                    'error' => $credentialError
                ], 422);
            }

            // Generate VPN configuration based on protocol
            $result = $this->generateByProtocol(
                $validated['protocol'],
                $server,
                $validated['client_name'],
                auth()->id()
            );

            return response()->json($result, 201);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage()
            ], 200);
        }
    }


    public function removeClient(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'client_name' => 'required|string|max:50',
            'server_id' => 'required|integer|exists:wireguards,id',
            'protocol' => 'required|string|in:wireguard',
        ]);

        try {
            // Retrieve server configuration from database
            $server = $this->getServerByProtocol(
                $validated['server_id'],
                $validated['protocol']
            );

            if (!$server) {
                return response()->json([
                    'success' => false,
                    'error' => 'Server not found or inactive'
                ], 404);
            }

            // Validate server has required credentials
            $credentialError = $this->validateServerCredentials($server);
            if ($credentialError) {
                return response()->json([
                    'success' => false,
                    'error' => $credentialError
                ], 422);
            }

            // Remove client based on protocol
            $result = $this->removeClientByProtocol(
                $validated['protocol'],
                $server,
                $validated['client_name']
            );

            return response()->json($result, 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage()
            ], 200);
        }
    }

    /**
     * Test SSH connection to a VPS server.
     * 
     * POST /api/vpn/test-connection
     *
     * @param Request $request The incoming HTTP request
     * @return JsonResponse Connection test result
     */
    public function testConnection(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'server_id' => 'required|integer|exists:wireguards,id',
            'protocol' => 'required|string|in:wireguard',
        ]);

        try {
            $server = $this->getServerByProtocol(
                $validated['server_id'],
                $validated['protocol']
            );

            if (!$server) {
                return response()->json([
                    'success' => false,
                    'error' => 'Server not found or inactive'
                ], 404);
            }

            $credentialError = $this->validateServerCredentials($server);
            if ($credentialError) {
                return response()->json([
                    'success' => false,
                    'error' => $credentialError
                ], 422);
            }

            $result = $this->vpnGenerator->testConnection(
                $this->buildServerCredentials($server)
            );

            return response()->json($result, $result['success'] ? 200 : 400);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage()
            ], 200);
        }
    }

    /**
     * List all VPN clients on a specific server.
     * 
     * POST /api/vpn/list-clients
     *
     * @param Request $request The incoming HTTP request
     * @return JsonResponse List of clients on the server
     */
    public function listClients(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'server_id' => 'required|integer|exists:wireguards,id',
            'protocol' => 'required|string|in:wireguard',
        ]);

        try {
            $server = $this->getServerByProtocol(
                $validated['server_id'],
                $validated['protocol']
            );

            if (!$server) {
                return response()->json([
                    'success' => false,
                    'error' => 'Server not found or inactive'
                ], 404);
            }

            $credentialError = $this->validateServerCredentials($server);
            if ($credentialError) {
                return response()->json([
                    'success' => false,
                    'error' => $credentialError
                ], 422);
            }

            $result = $this->vpnGenerator->listVPSClients(
                $this->buildServerCredentials($server)
            );

            return response()->json($result);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage()
            ], 200);
        }
    }

    /**
     * Revoke a VPN configuration by download token.
     * 
     * DELETE /api/vpn/config/{token}
     *
     * @param string $token The download token of the config to revoke
     * @return JsonResponse Result of the revocation operation
     */
    public function revoke(string $token): JsonResponse
    {
        $config = VpnConfig::where('download_token', $token)->first();

        if (!$config) {
            return response()->json([
                'success' => false,
                'error' => 'Config not found'
            ], 404);
        }

        $config->update(['status' => 'revoked']);

        return response()->json([
            'success' => true,
            'message' => 'Config revoked successfully'
        ]);
    }

    /**
     * Retrieve server configuration based on protocol type.
     *
     * @param int $serverId The server ID to retrieve
     * @param string $protocol The VPN protocol type
     * @return Wireguard|null The server model or null if not found
     */
    private function getServerByProtocol(int $serverId, string $protocol): ?Wireguard
    {
        // Currently only WireGuard is supported
        // Future protocols can be added here with their respective models
        return match ($protocol) {
            'wireguard' => Wireguard::where('id', $serverId)
                ->where('status', 1)
                ->first(),
            default => null,
        };
    }

    /**
     * Validate that server has all required credentials configured.
     *
     * @param Wireguard $server The server model to validate
     * @return string|null Error message if validation fails, null if valid
     */
    private function validateServerCredentials(Wireguard $server): ?string
    {
        if (empty($server->host)) {
            return 'Server host is not configured';
        }

        if (empty($server->vps_username)) {
            return 'VPS username is not configured';
        }

        if (empty($server->vps_password)) {
            return 'VPS password is not configured';
        }

        return null;
    }

    /**
     * Build server credentials array from server model.
     *
     * @param Wireguard $server The server model
     * @return array Server credentials array
     */
    private function buildServerCredentials(Wireguard $server): array
    {
        return [
            'host' => $server->host,
            'port' => $server->port ?? 22,
            'username' => $server->vps_username,
            'password' => $server->vps_password,
        ];
    }

    /**
     * Generate VPN configuration based on the specified protocol.
     *
     * @param string $protocol The VPN protocol type
     * @param Wireguard $server The server configuration
     * @param string $clientName The client name for the configuration
     * @param int|null $userId The authenticated user ID
     * @return array The generation result
     * @throws Exception When generation fails
     */
    private function generateByProtocol(
        string $protocol,
        Wireguard $server,
        string $clientName,
        ?int $userId
    ): array {
        // Currently only WireGuard is supported
        // Future protocols can implement their own generation logic here
        return match ($protocol) {
            'wireguard' => $this->vpnGenerator->generate(
                serverCredentials: $this->buildServerCredentials($server),
                clientName: $clientName,
                userId: $userId,
                expirationDays: 30
            ),
            default => throw new Exception("Unsupported protocol: {$protocol}"),
        };
    }

    /**
     * Remove VPN client based on the specified protocol.
     *
     * @param string $protocol The VPN protocol type
     * @param Wireguard $server The server configuration
     * @param string $clientName The client name to remove
     * @return array The removal result
     * @throws Exception When removal fails
     */
    private function removeClientByProtocol(
        string $protocol,
        Wireguard $server,
        string $clientName
    ): array {
        // Currently only WireGuard is supported
        // Future protocols can implement their own removal logic here
        return match ($protocol) {
            'wireguard' => $this->vpnGenerator->removeClient(
                serverCredentials: $this->buildServerCredentials($server),
                clientName: $clientName
            ),
            default => throw new Exception("Unsupported protocol: {$protocol}"),
        };
    }
}
