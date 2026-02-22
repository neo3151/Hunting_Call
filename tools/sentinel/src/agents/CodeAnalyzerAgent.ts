import { Agent, AgentRole, AgentTask } from '../core/Agent';
import * as fs from 'fs';
import * as path from 'path';

export class CodeAnalyzerAgent extends Agent {
    constructor(name: string) {
        super(name, AgentRole.CODE_ANALYZER);
        this.capabilities = ['code-analysis', 'filesystem', 'auditing'];
    }

    async processTask(task: AgentTask): Promise<AgentTask> {
        this.think(`Initializing code analyzer on target: ${task.description}`);

        const targetPath = task.params?.targetPath || process.cwd();
        const absolutePath = path.resolve(process.cwd(), targetPath);

        this.plan(`1. Resolve path: ${absolutePath}.
2. Read project configurations.
3. Traverse core source directories.
4. Extract structural metrics for reporting.`);

        this.log(`Analyzing project at: ${absolutePath}`);

        try {
            if (!fs.existsSync(absolutePath)) {
                task.status = 'failed';
                task.result = `Target path does not exist: ${absolutePath}`;
                return task;
            }

            const files = fs.readdirSync(absolutePath);
            let analysisReport = `Project Analysis for: ${absolutePath}\n`;
            let findings = 0;

            // Analyze Flutter/Dart Project
            if (files.includes('pubspec.yaml')) {
                this.think('Flutter environment detected. Reading pubspec...');
                const pubspecPath = path.join(absolutePath, 'pubspec.yaml');
                const pubspec = fs.readFileSync(pubspecPath, 'utf8');

                const nameMatch = pubspec.match(/name:\s*(.+)/);
                const versionMatch = pubspec.match(/version:\s*(.+)/);

                analysisReport += `\n[Flutter Metadata]\n`;
                analysisReport += `- App Name: ${nameMatch ? nameMatch[1] : 'Unknown'}\n`;
                analysisReport += `- Version: ${versionMatch ? versionMatch[1] : 'Unknown'}\n`;

                if (pubspec.includes('flutter_riverpod')) analysisReport += `- State Management: Riverpod detected.\n`;
                if (pubspec.includes('firebase_core')) analysisReport += `- Backend: Firebase integrated.\n`;
                findings++;
            }

            // Analyze Node.js Project
            if (files.includes('package.json')) {
                this.think('Node.js environment detected. Reading package.json...');
                const pkgPath = path.join(absolutePath, 'package.json');
                const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

                analysisReport += `\n[Node.js Metadata]\n`;
                analysisReport += `- App Name: ${pkg.name || 'Unknown'}\n`;
                analysisReport += `- Version: ${pkg.version || 'Unknown'}\n`;
                analysisReport += `- Dependencies: ${Object.keys(pkg.dependencies || {}).length}\n`;
                findings++;
            }

            // Traverse source code
            const srcDirs = ['src', 'lib', 'app'];
            for (const dir of srcDirs) {
                if (files.includes(dir)) {
                    const dirPath = path.join(absolutePath, dir);
                    const contents = fs.readdirSync(dirPath);
                    const filesOnly = contents.filter(item => fs.statSync(path.join(dirPath, item)).isFile());
                    const subDirs = contents.filter(item => fs.statSync(path.join(dirPath, item)).isDirectory());

                    analysisReport += `\n[Source Structure: ${dir}/]\n`;
                    analysisReport += `- Top-level Files: ${filesOnly.length}\n`;
                    analysisReport += `- Sub-modules: ${subDirs.join(', ')}\n`;
                    findings++;
                }
            }

            if (findings === 0) {
                analysisReport += "\nWarning: No standard project configurations (pubspec/package) or source directories (src/lib/app) found at root.";
            }

            // Optional simulated delay to emulate deep semantic scanning
            await new Promise(resolve => setTimeout(resolve, 800));

            task.result = analysisReport;
            task.status = 'completed';
            this.log(`Analysis complete. Found ${findings} structural signatures.`);
        } catch (error: any) {
            this.think(`CRITICAL: Analysis error encountered.`);
            task.status = 'failed';
            task.result = `Error reading filesystem: ${error.message}`;
        }

        return task;
    }
}
