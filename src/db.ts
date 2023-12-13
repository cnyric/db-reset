import type { Knex } from 'knex';
import knex from 'knex';
import { log } from './util.js';

function db(dbVals: string[]): Knex<any, unknown[]> {
  const [database, host, password] = dbVals;
  return knex({
    client: 'mssql',
    connection: {
      host,
      user: 'cnyric_service_account',
      password,
      database,
      requestTimeout: 1000 * 60 * 10,
      options: {
        trustServerCertificate: true
      }
    }
  });
}

export default db;
