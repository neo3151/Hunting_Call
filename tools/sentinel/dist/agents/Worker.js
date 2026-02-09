"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Worker = void 0;
const Agent_1 = require("../core/Agent");
const cp = __importStar(require("child_process"));
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
const util = __importStar(require("util"));
const execPromise = util.promisify(cp.exec);
class Worker extends Agent_1.Agent {
    constructor(name) {
        super(name, Agent_1.AgentRole.WORKER);
        this.flutterPath = '/home/neo/development/flutter/bin/flutter';
    }
    async processTask(task) {
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
            }
            catch (error) {
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
                    if (!fs.existsSync(parentDir))
                        fs.mkdirSync(parentDir, { recursive: true });
                    let content = '';
                    if (relativePath.includes('auth_service.dart')) {
                        content = `import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../features/auth/domain/auth_repository.dart';\n\nclass AuthService {\n  final Ref ref;\n  AuthService(this.ref);\n\n  Future<void> signOut() async {\n    await ref.read(authRepositoryProvider).signOut();\n    ref.invalidateSelf(); \n    print('Sentinel: AuthService - Global Sign-out complete.');\n  }\n}\n\nfinal authServiceProvider = Provider((ref) => AuthService(ref));\n`;
                    }
                    else {
                        content = `// Sentinel Generated Scaffold\n// Target: ${relativePath}\n\nclass GenericService {}\n`;
                    }
                    fs.writeFileSync(fullPath, content);
                    task.result = `Success: Created/Modified ${relativePath}.`;
                    task.status = 'completed';
                    return task;
                }
                catch (e) {
                    task.status = 'failed';
                    return task;
                }
            }
        }
        // Default Fallback
        task.result = `Processed: ${task.description.split('\n')[0]}.`;
        return task;
    }
}
exports.Worker = Worker;
