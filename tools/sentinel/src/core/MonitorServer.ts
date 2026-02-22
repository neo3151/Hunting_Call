
import express from 'express';
import cors from 'cors';
import { Logger } from './Logger';
import { Director } from '../agents/Director';

export class MonitorServer {
    private app: express.Application;
    private port: number;
    private director: Director;

    constructor(director: Director, port: number = 3000) {
        this.app = express();
        this.port = port;
        this.director = director;

        this.app.use(cors());
        this.app.use(express.json());

        // Serve the dashboard with no-cache headers to prevent stale logic
        this.app.use(express.static('dashboard', {
            etag: false,
            lastModified: false,
            setHeaders: (res, filePath) => {
                if (filePath.endsWith('.html')) {
                    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
                    res.setHeader('Pragma', 'no-cache');
                    res.setHeader('Expires', '0');
                }
            }
        }));

        this.setupRoutes();
    }

    private setupRoutes() {
        // Get recent logs from the memory buffer
        this.app.get('/api/logs', (req, res) => {
            res.json({
                logs: Logger.getRecentLogs()
            });
        });

        // Get current orchestrator state
        this.app.get('/api/state', (req, res) => {
            res.json({
                director: {
                    name: this.director.name,
                    activeWorkers: this.director.getWorkers().map(w => ({
                        name: w.name,
                        role: w.role,
                        capabilities: w.capabilities
                    })),
                    // We can expand this once we add more state tracking to Director
                }
            });
        });

        // Health check
        this.app.get('/api/status', (req, res) => {
            res.json({ status: 'Sentinel Core Online' });
        });
    }

    public start() {
        this.app.listen(this.port, '0.0.0.0', () => {
            Logger.info('MonitorServer', `Mission Control API listening on port ${this.port}`);
        });
    }
}
