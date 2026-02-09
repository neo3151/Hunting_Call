"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Agent = exports.AgentRole = void 0;
var AgentRole;
(function (AgentRole) {
    AgentRole["DIRECTOR"] = "Director";
    AgentRole["WORKER"] = "Worker";
    AgentRole["RESEARCHER"] = "Researcher";
    AgentRole["QA"] = "QA";
})(AgentRole || (exports.AgentRole = AgentRole = {}));
class Agent {
    constructor(name, role) {
        this.name = name;
        this.role = role;
    }
    log(message) {
        console.log(`[${this.role}] ${this.name}: ${message}`);
    }
}
exports.Agent = Agent;
