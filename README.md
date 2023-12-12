# Automated SchoolTool Training Database Reset

## Setup

### Install

```sh
git clone https://github.com/cnyric/db-reset.git
cd db-reset
npm install
```

### Build

```sh
npm run build
```

## Usage

Create a `.env` file in the root of the project with the following variables:

```sh
ENCRYPTION_KEY=[PASSWORD_ENCRYPTION_KEY] # Obtain from a colleague
PASSWORDS=[ENCRYPTED_SERVER_PASSWORDS] # Obtain from a colleague
SCHOOLTOOL_USER=[SCHOOLTOOL_USER] # Temp user to create in SchoolTool
SCHOOLTOOL_PASSWORD=[SCHOOLTOOL_PASSWORD] # Temp user's password
WINDOWS_USER=[WINDOWS_USER] # Windows user with access to `wwwroot`
WINDOWS_PASSWORD=[WINDOWS_PASSWORD] # Windows user's password
```

Obtain a copy of the `districts.json` data file from a colleague and place it in a `data` directory in the root of the project.

Then run the following command, where `[DISTRICT_SHORT_NAME]` is the short name of the district's SchoolTool instance:

```sh
node dist/index.js [DISTRICT_SHORT_NAME]
```

### Example

```sh
node dist/index.js ocmboces
```

## How It Works

The script will:

1. Look up the district's SchoolTool instance info in the `districts.json` file.
2. Import and transform the included SQL queries in the `queries` directory with district's info.
3. Connect to the district's SchoolTool instance and run the queries:
   1. Insert a stored procedure to log errors
   2. Backup the production database
   3. Restore the training database with the backup from production
   4. Reset the ID server in the training database
   5. Create a temp user in the training database
4. Update the timestamp on the district's `Web.config` file to trigger an IIS restart.
5. Login to the district's SchoolTool instance with the temp user and update the ID server.
6. Update the timestamp on the district's `Web.config` file to trigger an IIS restart.
