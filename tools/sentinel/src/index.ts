import { Director } from './agents/Director';
import { Worker } from './agents/Worker';
import { Researcher } from './agents/Researcher';
import { QA } from './agents/QA';
import { AgentTask } from './core/Agent';

async function main() {
    console.log('=== SENTINEL ORCHESTRATOR: MISSION - TOOLCHAIN VERIFY ===\n');

    const headAgent = new Director('Sentinel-Alpha');
    const engWorker = new Worker('Builder-Unit-01');
    const resWorker = new Researcher('Search-Unit-01');
    const qaWorker = new QA('Quality-Bot-01');

    headAgent.addWorker(engWorker);
    headAgent.addWorker(resWorker);
    headAgent.addWorker(qaWorker);

    // --- MISSION: DOCTOR ---
    console.log('--- MISSION: TOOLCHAIN CHECK ---');

    const doctorMission: AgentTask = {
        id: 'DOCTOR-01',
        description: 'Run flutter doctor to verify the development environment is ready for an app execution.',
        status: 'pending'
    };

    const finalResult = await headAgent.processTask(doctorMission);

    console.log('\n--- TOOLCHAIN REPORT ---');
    console.log(`Status: ${finalResult.status}`);
    console.log(`Summary:\n${finalResult.result}`);

    console.log('\n=== MISSION COMPLETE ===');
}

main().catch(console.error);
