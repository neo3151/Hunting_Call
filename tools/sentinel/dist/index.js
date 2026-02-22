"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Director_1 = require("./agents/Director");
const Worker_1 = require("./agents/Worker");
const Researcher_1 = require("./agents/Researcher");
const QAAgent_1 = require("./agents/QAAgent");
const ScoutAgent_1 = require("./agents/ScoutAgent");
const ArchitectAgent_1 = require("./agents/ArchitectAgent");
const OptimizerAgent_1 = require("./agents/OptimizerAgent");
const SecurityAgent_1 = require("./agents/SecurityAgent");
const TechnicalWriterAgent_1 = require("./agents/TechnicalWriterAgent");
const DevOpsAgent_1 = require("./agents/DevOpsAgent");
const CodeAnalyzerAgent_1 = require("./agents/CodeAnalyzerAgent");
const Logger_1 = require("./core/Logger");
const DashboardGenerator_1 = require("./core/DashboardGenerator");
async function main() {
    Logger_1.Logger.info('Main', '=== SENTINEL ORCHESTRATOR 4.0: TEAM OF EFFICIENCY ===');
    // 1. Setup Hierarchy
    const director = new Director_1.Director('Sentinel-Alpha');
    const worker = new Worker_1.Worker('Engineering-01');
    const researcher = new Researcher_1.Researcher('Intel-01');
    const qa = new QAAgent_1.QAAgent('Validator-01');
    const scout = new ScoutAgent_1.ScoutAgent('Pathfinder-01');
    const architect = new ArchitectAgent_1.ArchitectAgent('Master-Plan-01');
    const optimizer = new OptimizerAgent_1.OptimizerAgent('Speed-Demon-01');
    const security = new SecurityAgent_1.SecurityAgent('Lockdown-01');
    const technicalWriter = new TechnicalWriterAgent_1.TechnicalWriterAgent('Docs-Master-01');
    const devops = new DevOpsAgent_1.DevOpsAgent('Pipeline-Pro-01');
    const codeAnalyzer = new CodeAnalyzerAgent_1.CodeAnalyzerAgent('Deep-Scan-01');
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
    const tasks = [
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
    Logger_1.Logger.info('Main', '--- STARTING MISSION EXECUTION ---');
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
                Logger_1.Logger.debug('Main', `Dispatching ${activePromises.length} parallel task(s)...`);
                await Promise.all(activePromises);
            }
        }
        // Check if there are still running/pending tasks total
        const unfinishedCount = tasks.filter(t => t.status !== 'completed' && t.status !== 'failed').length;
        if (unfinishedCount > 0) {
            allCompleted = false;
            Logger_1.Logger.debug('Main', `Waiting for ${unfinishedCount} task(s) to resolve or re-route...`);
            await new Promise(resolve => setTimeout(resolve, 500));
        }
    }
    Logger_1.Logger.info('Main', '--- FINAL STATUS REPORT ---');
    tasks.forEach(t => {
        Logger_1.Logger.info('Main', `[${t.id}] Status: ${t.status} | Assigned: ${t.assignedTo}`);
    });
    Logger_1.Logger.info('Main', '--- SHARED KNOWLEDGE BASE FACTS ---');
    director.knowledgeBase.getAllFacts().forEach(f => {
        Logger_1.Logger.info('Main', `- ${f.key}: ${f.value} (Source: ${f.source})`);
    });
    director.persistKnowledge();
    // 4. Workplace Review & Dashboard
    const review = director.getWorkplaceReview();
    console.log(review);
    DashboardGenerator_1.DashboardGenerator.generate(director.knowledgeBase, tasks, review, 'dashboard.html');
    Logger_1.Logger.info('Main', 'Dashboard generated: dashboard.html');
    Logger_1.Logger.info('Main', '=== DEMO COMPLETE ===');
}
main().catch(err => {
    Logger_1.Logger.error('Main', `Fatal error: ${err}`);
});
