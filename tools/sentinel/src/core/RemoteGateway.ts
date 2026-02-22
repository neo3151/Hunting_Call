import { spawn } from 'child_process';
import { Logger } from './Logger';
import { DiscoveryService } from './DiscoveryService';

export class RemoteGateway {
    private port: number;
    private tunnelProcess: any | null = null;
    private currentUrl: string | null = null;

    constructor(port: number = 3000) {
        this.port = port;
    }

    /**
     * Starts a secure SSH tunnel via Serveo.net
     * No installation required, no password walls.
     */
    public async start(subdomain?: string): Promise<string | null> {
        return new Promise((resolve) => {
            Logger.info('RemoteGateway', `Initializing SSH tunnel for port ${this.port}...`);

            // Kill existing process if any
            if (this.tunnelProcess) {
                this.tunnelProcess.kill();
            }

            // Construct SSH args
            // -R 80:localhost:3000 serveo.net
            // Construct SSH args for Pinggy.io
            // ssh -p 443 -R0:localhost:3000 a.pinggy.io
            const sshArgs = [
                '-o', 'StrictHostKeyChecking=no',
                '-o', 'UserKnownHostsFile=/dev/null',
                '-p', '443',
                '-R0:localhost:' + this.port,
                'a.pinggy.io'
            ];

            Logger.debug('RemoteGateway', `Spawning: ssh ${sshArgs.join(' ')}`);
            this.tunnelProcess = spawn('ssh', sshArgs);

            let resolved = false;

            this.tunnelProcess.stdout.on('data', (data: any) => {
                const output = data.toString();
                // Pinggy outputs URL in stdout
                const match = output.match(/https:\/\/[a-zA-Z0-9-]+\.a\.free\.pinggy\.link/);

                if (match && !resolved) {
                    this.currentUrl = match[0];
                    resolved = true;
                    this.onTunnelEstablished(match[0]);
                    resolve(match[0]);
                }
            });

            // Serveo sometimes outputs to stderr
            this.tunnelProcess.stderr.on('data', (data: any) => {
                const output = data.toString();
                // Check for URL in stderr too (Pinggy banner)
                const match = output.match(/https:\/\/[a-zA-Z0-9-]+\.a\.free\.pinggy\.link/);
                if (match && !resolved) {
                    this.currentUrl = match[0];
                    resolved = true;
                    this.onTunnelEstablished(match[0]);
                    resolve(match[0]);
                }
            });

            this.tunnelProcess.on('close', (code: number) => {
                Logger.warn('RemoteGateway', `SSH tunnel closed (code ${code}). Reconnecting in 5s...`);
                this.currentUrl = null;
                // Retry with same subdomain config
                setTimeout(() => this.start(subdomain), 5000);
            });

            // Timeout if no URL found in 10s
            setTimeout(() => {
                if (!resolved) {
                    Logger.warn('RemoteGateway', 'Tunnel negotiation timed out. Continuing without remote access.');
                    resolve(null);
                }
            }, 10000);
        });
    }

    private async onTunnelEstablished(url: string) {
        Logger.info('RemoteGateway', `Global Mission Control Live: ${url}`);
        Logger.plan('RemoteGateway', `1. Secure SSH Tunnel established.`);
        Logger.plan('RemoteGateway', `2. Remote URL: ${url}`);
        Logger.plan('RemoteGateway', `3. Access Control: PASSWORD-FREE (Direct Access)`);

        // Update Discovery for Mobile Apps
        await DiscoveryService.reportRemoteUrl(url, "NO_PASSWORD_REQUIRED");
    }

    public close() {
        if (this.tunnelProcess) {
            this.tunnelProcess.kill();
            this.tunnelProcess = null;
        }
    }
}
