# Automated SchoolTool Training Database Reset

## Setup

- Ensure all servers are reachable over SMB and SQL from the machine running the script.
- Create a service account on each SQL server and store the password in an array, ordered by cluster number, to encrypt with `dist/encrypt-pws.js`.
- Create a share on each district's web servers at `D:\inetpub\wwwroot`, granting the designated Windows user `Full Control`.

### Install

Requires Node v18.x.

```bash
sudo apt install smbclient
git clone https://github.com/cnyric/db-reset.git
cd db-reset
npm install
```

### Build

```bash
npm run build
```

## Usage

Create a `.env` file in the root of the project with the following variables:

```bash
ENCRYPTION_KEY=[PASSWORD_ENCRYPTION_KEY] # Obtain from a colleague
PASSWORDS=[ENCRYPTED_SERVER_PASSWORDS] # Obtain from a colleague
SCHOOLTOOL_USER=[SCHOOLTOOL_USER] # Temp user to create in SchoolTool
SCHOOLTOOL_PASSWORD=[SCHOOLTOOL_PASSWORD] # Temp user's password
WINDOWS_USER=[WINDOWS_USER] # Windows user with access to `wwwroot`
WINDOWS_PASSWORD=[WINDOWS_PASSWORD] # Windows user's password
```

Obtain a copy of the `districts.json` data file from a colleague and place it in a `data` directory in the root of the project. See `src/districts.schema.json` for the expected format.

Then run the following command, where `[DISTRICT_SHORT_NAME]` is the short name of the district's SchoolTool instance:

```bash
node dist/index.js [DISTRICT_SHORT_NAME]
```

### Example

```bash
> node dist/index.js scramble

2023-12-12 20:46:50.975 INFO    /dist/districts.js:5    Getting district info for `scramble`...
2023-12-12 20:46:51.135 INFO    /dist/index.js:38       Creating LogError stored procedure...
2023-12-12 20:46:51.166 WARN    /dist/index.js:42       LogError SP already exists
2023-12-12 20:46:51.166 INFO    /dist/index.js:44       Restoring database...
2023-12-12 20:47:46.776 INFO    /dist/index.js:47       Creating user...
2023-12-12 20:47:46.814 INFO    /dist/touch-config.js:7 Touching `scramble` config on `stwebrptcnyric`...
2023-12-12 20:47:48.202 INFO    /dist/index.js:54       Updating ID Server...
2023-12-12 20:48:02.965 INFO    /dist/touch-config.js:7 Touching `scramble` config on `stwebrptcnyric`...
```

## How It Works

The script will:

1. Look up the district's SchoolTool instance info in the `districts.json` file (`src/districts.ts`).
2. Import and transform the included SQL queries in the `queries` directory with the district's info (`src/index.ts`).
3. Connect to the district's database instance and run the queries:
   1. Insert a stored procedure to log errors (`queries/log-error.sql`)
   2. Backup the production database (`queries/restore.sql`)
   3. Restore the training database with the backup from production (`"`)
   4. Reset the ID server in the training database (`"`)
   5. Create a temp user in the training database (`queries/create-user.sql`)
4. Update the timestamp on the district's `Web.config` file(s) to trigger an IIS restart (`src/touch-config.ts`).
5. Login to the district's SchoolTool frontend with the temp user and update the ID server (`src/update-id-server.ts`).
6. Again, update the timestamp on the district's `Web.config` file(s) to trigger an IIS restart.
