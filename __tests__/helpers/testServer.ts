/**
 * Test Server Helper
 * Starts the Express server from examples/express-app for E2E testing.
 * Supports both SQLite (default) and PostgreSQL (when DB_DIALECT=postgres).
 */
import { ChildProcess, spawn } from 'child_process';

let serverProcess: ChildProcess | null = null;

function isPostgres(): boolean {
  return (process.env.DB_DIALECT || '').startsWith('postgres');
}

/**
 * Start the test server by running the example Express app
 */
export async function startTestServer(port = 3001): Promise<ChildProcess> {
  let env: Record<string, string>;

  if (isPostgres()) {
    // PostgreSQL mode — create schema/seed via pg client
    console.log('🚀 Creating PostgreSQL test database...');
    const pg = require('../db/postgres');
    await pg.createTestDatabase();

    env = {
      ...process.env as any,
      PORT: port.toString(),
      port: port.toString(),
      DB_DIALECT: 'postgres',
      DB_HOST: process.env.DB_HOST || 'localhost',
      DB_PORT: process.env.DB_PORT || '5433',
      DB_NAME: process.env.DB_NAME || 'odata_test',
      DB_USER: process.env.DB_USER || 'odata',
      DB_PASSWORD: process.env.DB_PASSWORD || 'odata',
      DB_SCHEMA: process.env.DB_SCHEMA || 'public',
    };
  } else {
    // SQLite mode (original behavior)
    console.log('🚀 Creating SQLite test database...');
    const sqlite = require('../db');
    await sqlite.createTestDatabase();

    const dbPath = require('path').join(__dirname, '../db/test.db');
    env = {
      ...process.env as any,
      PORT: port.toString(),
      port: port.toString(),
      DB_PATH: dbPath,
      DB_DIALECT: 'sqlite',
      DB_NAME: dbPath,
      DB_SCHEMA: '',
    };
  }

  console.log('🚀 Starting Express server...');

  return new Promise((resolve, reject) => {
    // Start the Express server using ts-node
    serverProcess = spawn('npx', ['ts-node', 'examples/express-app/server.ts'], {
      env,
      stdio: 'pipe',
    });

    let serverStarted = false;

    // Listen for server output
    serverProcess.stdout?.on('data', data => {
      const output = data.toString();
      console.log(output);

      // Check if server has started
      if (output.includes('Server listening on port')) {
        serverStarted = true;
        console.log(`✅ Test server started on port ${port}`);
        resolve(serverProcess!);
      }
    });

    serverProcess.stderr?.on('data', data => {
      console.error('Server error:', data.toString());
    });

    serverProcess.on('error', error => {
      if (!serverStarted) {
        console.error('❌ Failed to start test server:', error);
        reject(error);
      }
    });

    serverProcess.on('exit', (code, signal) => {
      if (!serverStarted) {
        reject(new Error(`Server process exited with code ${code} and signal ${signal}`));
      }
    });

    // Timeout after 15 seconds (PostgreSQL may take longer to connect)
    setTimeout(() => {
      if (!serverStarted) {
        reject(new Error('Server failed to start within 15 seconds'));
      }
    }, 15000);
  });
}

/**
 * Stop the test server and close database
 */
export async function stopTestServer(server: ChildProcess): Promise<void> {
  console.log('🛑 Stopping test server...');

  return new Promise(async resolve => {
    if (server && !server.killed) {
      server.on('exit', async () => {
        console.log('✅ Test server stopped');
        await closeDb();
        serverProcess = null;
        resolve();
      });

      // Kill the server process
      server.kill('SIGTERM');

      // Force kill after 5 seconds if not stopped
      setTimeout(() => {
        if (server && !server.killed) {
          server.kill('SIGKILL');
        }
      }, 5000);
    } else {
      await closeDb();
      resolve();
    }
  });
}

async function closeDb(): Promise<void> {
  if (isPostgres()) {
    const pg = require('../db/postgres');
    await pg.closeTestDatabase();
  } else {
    const sqlite = require('../db');
    await sqlite.closeTestDatabase();
  }
}
