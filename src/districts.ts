import { readFile } from 'fs/promises';
import { Districts, District, RefinedDistrict, Cluster, Site } from '@@types';
import Iron from '@hapi/iron';
import { log } from './util.js';

async function getDistrict(code: string): Promise<RefinedDistrict> {
  log.info(`Getting district info for \`${code}\`...`);

  // look up district
  const districts = JSON.parse(await readFile(`${process.cwd()}/data/districts.json`, 'utf-8')) as Districts;

  // get district info
  const districtInfo = districts.districts.find((d: any) => d.code === code) as District;

  // get district name
  const name = districtInfo?.district;

  // get cluster id number
  const clusterNum = districtInfo?.cluster as number;

  // get cluster info
  const cluster = districts.clusters[clusterNum] as Cluster;

  // get server info
  const web = cluster.servers.find(s => s.service === 'Web')?.hostname as string;
  const sql = cluster.servers.find(s => s.service === 'SQL')?.hostname as string;

  // get site info
  const { production, training } = cluster.sites.find(s => s.district === name) as Site;

  // get db name
  const database = `${code === 'scramble' ? 'scramble01' : code}`;

  // get db password
  const password = (
    await Iron.unseal(process.env.PASSWORDS as string, process.env.ENCRYPTION_KEY as string, Iron.defaults)
  )[clusterNum];

  return {
    name,
    code,
    cluster: clusterNum,
    production,
    training,
    web,
    sql,
    database,
    password
  };
}

export { getDistrict };
