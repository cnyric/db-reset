export interface Districts {
  clusters: { [key: string]: Cluster };
  districts: District[];
}

export interface Cluster {
  servers: Server[];
  sites: Site[];
}

export interface Server {
  hostname: string;
  ip: string;
  service: Service;
  tailscale_ip: string;
}

export enum Service {
  Report = 'Report',
  SQL = 'SQL',
  Web = 'Web'
}

export interface Site {
  district: string;
  production: string;
  training?: string;
}

export interface District {
  cluster: number;
  code: string;
  district: string;
}

export interface RefinedDistrict {
  name: string;
  code: string;
  cluster: number;
  web: string[];
  sql: string;
  production: string;
  training?: string;
  database: string;
  password: string;
}
