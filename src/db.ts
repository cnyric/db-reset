import knex from 'knex';
import type { Knex } from 'knex';
import { log } from './util.js';

function db(dbVals: string[]): Knex<any, unknown[]> {
  const [database, host, password] = dbVals;
  // log.debug(database, host, password);

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
