import Iron from '@hapi/iron';
import dotenv from 'dotenv';
import { log } from './util.js';

dotenv.config();

const obj = [
  // password list
  'password1'
];

async function main() {
  try {
    const token = await Iron.seal(obj, process.env.ENCRYPTION_KEY as string, Iron.defaults);
    log.debug(token);
  } catch (error) {
    log.error(error);
  }
}

main();
