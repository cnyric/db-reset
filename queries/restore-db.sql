-- Set the source and destination database names
DECLARE @sourceDatabaseName NVARCHAR (128) = 'REPLACE_DATABASE_NAME';
DECLARE @destinationDatabaseName NVARCHAR (128) = @sourceDatabaseName + 'Training';

-- Set the backup file path
DECLARE @backupFilePath NVARCHAR (256) = 'C:\Windows\Temp\' +  @sourceDatabaseName + '.bak';

-- Set the destination database to single user mode
DECLARE @singleUser NVARCHAR(MAX) = 'ALTER DATABASE ' + QUOTENAME(@destinationDatabaseName) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
EXEC sp_executesql @singleUser;

-- Backup the source database
DECLARE @backupDb NVARCHAR(MAX) = N'BACKUP DATABASE ' + QUOTENAME(@sourceDatabaseName) + N' TO DISK = ''' + @backupFilePath + ''' WITH FORMAT';
BEGIN TRY
    EXEC sp_executesql @backupDb, N'@overrideCheck INT', @overrideCheck = 1;
END TRY
BEGIN CATCH
    EXEC LogError;
END CATCH;

-- Restore the database
DECLARE @restoreDb NVARCHAR(MAX) = N'RESTORE DATABASE ' + QUOTENAME(@destinationDatabaseName) + N' FROM DISK = ''' + @backupFilePath + ''' WITH REPLACE';
BEGIN TRY
    EXEC sp_executesql @restoreDb, N'@overrideCheck INT', @overrideCheck = 1;
END TRY
BEGIN CATCH
    EXEC LogError;
END CATCH;

-- Set the destination database to multi user mode
DECLARE @multiUser NVARCHAR(MAX) = 'ALTER DATABASE ' + QUOTENAME(@destinationDatabaseName) + ' SET MULTI_USER;';
EXEC sp_executesql @multiUser;
