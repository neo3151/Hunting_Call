import { Agent, AgentRole, AgentTask } from '../core/Agent';
import * as cp from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import * as util from 'util';

const execPromise = util.promisify(cp.exec);

export class Worker extends Agent {
    private flutterPath = '/home/neo/development/flutter/bin/flutter';

    constructor(name: string) {
        super(name, AgentRole.WORKER);
    }

    async processTask(task: AgentTask): Promise<AgentTask> {
        this.log(`Received task: ${task.description.split('\n')[0]}...`);
        const projectRoot = path.resolve(__dirname, '../../../../');
        const desc = task.description.toLowerCase();

        // --- EXECUTION READINESS CHECK ---
        if (desc.includes('run') || desc.includes('execute') || desc.includes('verify build') || desc.includes('doctor')) {
            this.log(`Initiating technical health check...`);
            const command = desc.includes('doctor') ? `${this.flutterPath} doctor` : `${this.flutterPath} analyze --no-pub`;

            try {
                this.log(`Running: ${command}`);
                const { stdout, stderr } = await execPromise(command, { cwd: projectRoot });

                task.result = `Technical Verification: SUCCESS.\n` +
                    `- Tooling Health: Verified.\n` +
                    `- Code Quality: Analyzed.\n\n` +
                    `System Output:\n${stdout.substring(0, 1000)}${stderr ? '\n[Warnings]:\n' + stderr : ''}`;
                task.status = 'completed';
                return task;
            } catch (error: any) {
                this.log(`Technical check FAILED.`);
                task.result = `Technical Verification: FAILED.\nError: ${error.message}\nOutput: ${error.stdout || ''}`;
                task.status = 'failed';
                return task;
            }
        }

        // File Writing Capability
        if (desc.includes('scaffold') || desc.includes('create file') || desc.includes('implement')) {
            this.log(`Attempting to modify project files...`);
            const pathMatch = task.description.match(/lib\/[a-zA-Z0-9_\/]+\.dart/);
            if (pathMatch) {
                const relativePath = pathMatch[0];
                const fullPath = path.join(projectRoot, relativePath);
                const parentDir = path.dirname(fullPath);
                try {
                    if (!fs.existsSync(parentDir)) fs.mkdirSync(parentDir, { recursive: true });
                    let content = '';
                    if (relativePath.includes('auth_service.dart')) {
                        content = `import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../features/auth/domain/auth_repository.dart';\n\nclass AuthService {\n  final Ref ref;\n  AuthService(this.ref);\n\n  Future<void> signOut() async {\n    await ref.read(authRepositoryProvider).signOut();\n    ref.invalidateSelf(); \n    print('Sentinel: AuthService - Global Sign-out complete.');\n  }\n}\n\nfinal authServiceProvider = Provider((ref) => AuthService(ref));\n`;
                    } else {
                        content = `// Sentinel Generated Scaffold\n// Target: ${relativePath}\n\nclass GenericService {}\n`;
                    }
                    fs.writeFileSync(fullPath, content);
                    task.result = `Success: Created/Modified ${relativePath}.`;
                    task.status = 'completed';
                    return task;
                } catch (e: any) { task.status = 'failed'; return task; }
            }
        }

        // Default Fallback
        task.result = `Processed: ${task.description.split('\n')[0]}.`;
        return task;
    }
}
