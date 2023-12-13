import type { ILogObj } from 'tslog';
import { Logger } from 'tslog';

const log: Logger<ILogObj> = new Logger();

export { log };
