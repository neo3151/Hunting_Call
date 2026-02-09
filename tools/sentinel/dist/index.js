"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Director_1 = require("./agents/Director");
const Worker_1 = require("./agents/Worker");
const Researcher_1 = require("./agents/Researcher");
const QA_1 = require("./agents/QA");
async function main() {
    console.log('=== SENTINEL ORCHESTRATOR: MISSION - TOOLCHAIN VERIFY ===\n');
    const headAgent = new Director_1.Director('Sentinel-Alpha');
    const engWorker = new Worker_1.Worker('Builder-Unit-01');
    const resWorker = new Researcher_1.Researcher('Search-Unit-01');
    const qaWorker = new QA_1.QA('Quality-Bot-01');
    headAgent.addWorker(engWorker);
    headAgent.addWorker(resWorker);
    headAgent.addWorker(qaWorker);
    // --- MISSION: DOCTOR ---
    console.log('--- MISSION: TOOLCHAIN CHECK ---');
    const doctorMission = {
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
