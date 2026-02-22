import { Director } from './agents/Director';
import { Worker } from './agents/Worker';
import { Researcher } from './agents/Researcher';
import { QAAgent } from './agents/QAAgent';
import { ScoutAgent } from './agents/ScoutAgent';
import { ArchitectAgent } from './agents/ArchitectAgent';
import { OptimizerAgent } from './agents/OptimizerAgent';
import { SecurityAgent } from './agents/SecurityAgent';
import { TechnicalWriterAgent } from './agents/TechnicalWriterAgent';
import { DevOpsAgent } from './agents/DevOpsAgent';
import { CodeAnalyzerAgent } from './agents/CodeAnalyzerAgent';
import { AgentTask } from './core/Agent';
import { Logger } from './core/Logger';
import { DashboardGenerator } from './core/DashboardGenerator';

async function main() {
    Logger.info('Main', '=== SENTINEL ORCHESTRATOR 4.0: TEAM OF EFFICIENCY ===');

    // 1. Setup Hierarchy
    const director = new Director('Sentinel-Alpha');
    const worker = new Worker('Engineering-01');
    const researcher = new Researcher('Intel-01');
    const qa = new QAAgent('Validator-01');
    const scout = new ScoutAgent('Pathfinder-01');
    const architect = new ArchitectAgent('Master-Plan-01');
    const optimizer = new OptimizerAgent('Speed-Demon-01');
    const security = new SecurityAgent('Lockdown-01');
    const technicalWriter = new TechnicalWriterAgent('Docs-Master-01');
    const devops = new DevOpsAgent('Pipeline-Pro-01');
    const codeAnalyzer = new CodeAnalyzerAgent('Deep-Scan-01');

    director.addWorker(worker);
    director.addWorker(researcher);
    director.addWorker(qa);
    director.addWorker(scout);
    director.addWorker(architect);
    director.addWorker(optimizer);
    director.addWorker(security);
    director.addWorker(technicalWriter);
    director.addWorker(devops);
    director.addWorker(codeAnalyzer);

    // 2. Define Mission Stack: Hunting_Call_New Codebase Analysis
    const targetProject = '/home/neo/Hunting_Call_New';

    const tasks: AgentTask[] = [
        {
            id: 'T-DISCOVER-PROJECT',
            description: `Verify and scout the target project directory: ${targetProject}`,
            status: 'pending',
            params: { targetPath: targetProject }
        },
        {
            id: 'T-ANALYZE-CODEBASE',
            description: `Deep scan the configuration files and source modules inside ${targetProject}`,
            status: 'pending',
            dependencies: ['T-DISCOVER-PROJECT'],
            params: { targetPath: targetProject }
        },
        {
            id: 'T-PROJECT-REPORT',
            description: `Draft comprehensive architecture summary and audit report based on findings`,
            status: 'pending',
            dependencies: ['T-ANALYZE-CODEBASE']
        }
    ];

    // 3. Execution Engine
    Logger.info('Main', '--- STARTING MISSION EXECUTION ---');

    let allCompleted = false;
    while (!allCompleted) {
        allCompleted = true;

        // Find tasks that are ready to go right now
        const readyTasks = tasks.filter(t => t.status === 'pending' || t.status === 'waiting');

        if (readyTasks.length > 0) {
            allCompleted = false;

            // Map ready tasks to active promises and execute them simultaneously
            const activePromises = readyTasks.map(task => director.processTask(task, tasks));

            if (activePromises.length > 0) {
                Logger.debug('Main', `Dispatching ${activePromises.length} parallel task(s)...`);
                await Promise.all(activePromises);
            }
        }

        // Check if there are still running/pending tasks total
        const unfinishedCount = tasks.filter(t => t.status !== 'completed' && t.status !== 'failed').length;
        if (unfinishedCount > 0) {
            allCompleted = false;
            Logger.debug('Main', `Waiting for ${unfinishedCount} task(s) to resolve or re-route...`);
            await new Promise(resolve => setTimeout(resolve, 500));
        }
    }

    Logger.info('Main', '--- FINAL STATUS REPORT ---');
    tasks.forEach(t => {
        Logger.info('Main', `[${t.id}] Status: ${t.status} | Assigned: ${t.assignedTo}`);
    });

    Logger.info('Main', '--- SHARED KNOWLEDGE BASE FACTS ---');
    director.knowledgeBase.getAllFacts().forEach(f => {
        Logger.info('Main', `- ${f.key}: ${f.value} (Source: ${f.source})`);
    });
    director.persistKnowledge();

    // 4. Workplace Review & Dashboard
    const review = director.getWorkplaceReview();
    console.log(review);

    DashboardGenerator.generate(director.knowledgeBase, tasks, review, 'dashboard.html');
    Logger.info('Main', 'Dashboard generated: dashboard.html');

    Logger.info('Main', '=== DEMO COMPLETE ===');
}

main().catch(err => {
    Logger.error('Main', `Fatal error: ${err}`);
});
