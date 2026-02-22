"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Agent = exports.AgentRole = void 0;
const Logger_1 = require("./Logger");
var AgentRole;
(function (AgentRole) {
    AgentRole["DIRECTOR"] = "Director";
    AgentRole["WORKER"] = "Worker";
    AgentRole["RESEARCHER"] = "Researcher";
    AgentRole["QA"] = "QA";
    AgentRole["SCOUT"] = "Scout";
    AgentRole["ARCHITECT"] = "Architect";
    AgentRole["OPTIMIZER"] = "Optimizer";
    AgentRole["SECURITY"] = "Security";
    AgentRole["TECHNICAL_WRITER"] = "TechnicalWriter";
    AgentRole["DEVOPS"] = "DevOps";
    AgentRole["CODE_ANALYZER"] = "CodeAnalyzer";
})(AgentRole || (exports.AgentRole = AgentRole = {}));
class Agent {
    constructor(name, role) {
        this.name = name;
        this.role = role;
        this.capabilities = [];
        this.isBusy = false;
    }
    setKnowledgeBase(kb) {
        this.knowledgeBase = kb;
    }
    log(message, missionId) {
        Logger_1.Logger.info(`${this.role}:${this.name}`, message, missionId);
    }
    think(message, missionId) {
        Logger_1.Logger.thought(`${this.role}:${this.name}`, message, missionId);
    }
    plan(message, missionId) {
        Logger_1.Logger.plan(`${this.role}:${this.name}`, message, missionId);
    }
    speak(message, missionId) {
        // "Spoken" messages are just INFO logs but intended for the Chat UI
        Logger_1.Logger.info(`${this.role}:${this.name}`, message, missionId);
    }
}
exports.Agent = Agent;
