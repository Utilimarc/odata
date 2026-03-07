/**
 * PostgreSQL Test Database Helper
 * Creates and manages a PostgreSQL database for testing
 *
 * Expects environment variables:
 *   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
 */

import * as fs from 'fs';
import * as path from 'path';

// Use dynamic require so this file can be imported even if pg isn't installed
let Client: any;
try {
  Client = require('pg').Client;
} catch {
  // pg not available - will fail at runtime if actually used
}

let client: any = null;

function getConnectionConfig() {
  return {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5433'),
    database: process.env.DB_NAME || 'odata_test',
    user: process.env.DB_USER || 'odata',
    password: process.env.DB_PASSWORD || 'odata',
  };
}

/**
 * Create PostgreSQL schema and seed data for testing.
 * Uses the demo-setup.sql which includes both DDL and seed data.
 */
export async function createTestDatabase(): Promise<void> {
  if (!Client) {
    throw new Error('pg package is required for PostgreSQL tests. Run: npm install');
  }

  const config = getConnectionConfig();
  client = new Client(config);
  await client.connect();

  const setupSql = fs.readFileSync(
    path.join(__dirname, '../../examples/express-app/demo-setup.sql'),
    'utf8',
  );
  await client.query(setupSql);
}

/**
 * Close the PostgreSQL connection
 */
export async function closeTestDatabase(): Promise<void> {
  if (client) {
    await client.end();
    client = null;
  }
}
