
import { Director } from './src/agents/Director';
import { ScoutAgent } from './src/agents/ScoutAgent';
import { Researcher } from './src/agents/Researcher';
import { MonitorServer } from './src/core/MonitorServer';
import { RemoteGateway } from './src/core/RemoteGateway';
import { AgentTask } from './src/core/Agent';
import { Logger } from './src/core/Logger';

async function startPersistentDashboard() {
    const director = new Director('Astra-Prime');
    director.addWorker(new ScoutAgent('Scout-Alpha'));
    director.addWorker(new Researcher('Sage-Beta'));

    const server = new MonitorServer(director, 3000);
    server.start();

    const gateway = new RemoteGateway(3000);
    const publicUrl = await gateway.start();

    if (publicUrl) {
        console.log(`\n[GLOBAL ACCESS ENABLED]`);
        console.log(`Mission Control is live at: ${publicUrl}`);
    }

    // Loop mission to keep logs moving
    while (true) {
        const mission: AgentTask = {
            id: `Heartbeat-${Date.now()}`,
            description: 'Maintaining active monitoring pulse...',
            status: 'pending',
            params: { targetPath: '.' }
        };
        await director.processTask(mission);
        await new Promise(resolve => setTimeout(resolve, 5000));
    }
}

startPersistentDashboard().catch(console.error);
