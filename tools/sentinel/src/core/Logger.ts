import * as fs from 'fs';
import * as path from 'path';

export enum LogLevel {
    INFO = 'INFO',
    WARN = 'WARN',
    ERROR = 'ERROR',
    DEBUG = 'DEBUG',
    THOUGHT = 'THOUGHT',
    PLAN = 'PLAN'
}

export interface LogEntry {
    id: string;
    timestamp: string;
    level: LogLevel;
    context: string;
    message: string;
    missionId?: string;
}

export class Logger {
    private static logFile: string = path.join(process.cwd(), 'sentinel.log');

    static setLogFile(filePath: string) {
        this.logFile = filePath;
    }

    private static logBuffer: LogEntry[] = [];
    private static readonly MAX_BUFFER_SIZE = 200;

    static log(level: LogLevel, context: string, message: string, missionId?: string) {
        const entry: LogEntry = {
            id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
            timestamp: new Date().toISOString(),
            level,
            context,
            message,
            missionId
        };

        // Update memory buffer
        this.logBuffer.push(entry);
        if (this.logBuffer.length > this.MAX_BUFFER_SIZE) {
            this.logBuffer.shift();
        }

        // Console output (Human readable)
        const colors = {
            [LogLevel.INFO]: '\x1b[32m',    // Green
            [LogLevel.WARN]: '\x1b[33m',    // Yellow
            [LogLevel.ERROR]: '\x1b[31m',   // Red
            [LogLevel.DEBUG]: '\x1b[34m',   // Blue
            [LogLevel.THOUGHT]: '\x1b[35m', // Magenta
            [LogLevel.PLAN]: '\x1b[36m',    // Cyan
        };
        const reset = '\x1b[0m';
        const formatted = `[${entry.timestamp}] [${level}] [${context}] ${message} ${missionId ? `(Mission: ${missionId})` : ''}`;

        console.log(`${colors[level]}${formatted}${reset}`);

        // File output
        try {
            fs.appendFileSync(this.logFile, formatted + '\n');
        } catch (err) {
            console.error(`Failed to write to log file: ${err}`);
        }
    }

    static getRecentLogs(): LogEntry[] {
        return [...this.logBuffer];
    }

    static info(context: string, message: string, missionId?: string) { this.log(LogLevel.INFO, context, message, missionId); }
    static warn(context: string, message: string, missionId?: string) { this.log(LogLevel.WARN, context, message, missionId); }
    static error(context: string, message: string, missionId?: string) { this.log(LogLevel.ERROR, context, message, missionId); }
    static debug(context: string, message: string, missionId?: string) { this.log(LogLevel.DEBUG, context, message, missionId); }
    static thought(context: string, message: string, missionId?: string) { this.log(LogLevel.THOUGHT, context, message, missionId); }
    static plan(context: string, message: string, missionId?: string) { this.log(LogLevel.PLAN, context, message, missionId); }
}
