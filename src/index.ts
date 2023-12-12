import { RefinedDistrict } from '@@types';

import dotenv from 'dotenv';
import { readFile } from 'fs/promises';

import touchConfig from './touch-config.js';
import updateIdServer from './update-id-server.js';
import { getDistrict } from './districts.js';
import db from './db.js';

import { log } from './util.js';

dotenv.config();

async function main() {
  try {
    // set connection values
    const district = await getDistrict('scramble');
    const dbParams: string[] = [district.database, district.sql, district.password];

    // load sql queries
    const logErrorSp = await readFile(`${process.cwd()}/queries/log-error.sql`, 'utf-8');
    const restoreDb = (await readFile(`${process.cwd()}/queries/restore-db.sql`, 'utf-8')).replace(
      'REPLACE_DATABASE_NAME',
      district.database
    );
    const createUser = (await readFile(`${process.cwd()}/queries/create-user.sql`, 'utf-8'))
      .replace('REPLACE_EMAIL', process.env.SCHOOLTOOL_USER as string)
      .replace('REPLACE_PASSWORD', process.env.SCHOOLTOOL_PASSWORD as string);

    // prep query engine
    await db(dbParams).raw(`
      SET ANSI_NULLS ON;
      SET NOCOUNT ON;
      SET QUOTED_IDENTIFIER ON;
      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
      USE MASTER;
    `);

    // create logError SP
    try {
      await db(dbParams).raw(logErrorSp);
    } catch (error) {
      log.warn('LogError SP already exists');
    }

    // restore db
    await db(dbParams).raw(restoreDb);

    // create user
    try {
      await db(dbParams).raw(createUser);
    } catch (error) {
      log.warn('User already exists');
    }

    // touch config
    await touchConfig(district);

    // update id server
    try {
      await updateIdServer(district);
    } catch (error) {
      log.error(error);
    }

    // touch config
    await touchConfig(district);

    process.exit(0);
  } catch (error) {
    log.error(error);
    process.exit(1);
  }
}

main();
