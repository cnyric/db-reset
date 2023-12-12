import { RefinedDistrict } from '@@types';

import dns from 'dns/promises';
import { tmpdir } from 'os';
import { execa } from 'execa';

import { log } from './util.js';

async function touchConfig(district: RefinedDistrict) {
  const share = await dns.lookup(district.web);

  const config = {
    share: `//${share.address}/wwwroot`,
    domain: district.cluster === 0 ? 'CNYRIC' : 'STCNYRIC',
    username: process.env.WINDOWS_USER as string,
    password: process.env.WINDOWS_PASSWORD as string
  };

  const base = [config.share, '-U', `${config.domain}/${config.username}%${config.password}`, '-c'];

  const resGet = await execa('/usr/bin/smbclient', [
    ...base,
    `prompt OFF; lcd ${tmpdir()}; get ${district.database}Training\\Web.config ${district.database}Training.config`
  ]);
  // log.debug('resGet', resGet);

  const resPut = await execa('/usr/bin/smbclient', [
    ...base,
    `prompt OFF; lcd ${tmpdir()}; put ${district.database}Training.config ${district.database}Training\\Web.config`
  ]);
  // log.debug('resPut', resPut);
}

export default touchConfig;
