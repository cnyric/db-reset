-- Set the source and destination database names
DECLARE @sourceDatabaseName NVARCHAR (128) = 'REPLACE_DATABASE_NAME';
DECLARE @destinationDatabaseName NVARCHAR (128) = @sourceDatabaseName + 'Training';

-- Reset the identity server config
DECLARE @resetId NVARCHAR(MAX) = N'USE ' + QUOTENAME(@destinationDatabaseName) + N'; EXEC spIdentityServerUndoConfiguration @UndoType = ''refresh'', @overrideCheck = 1;';
BEGIN TRY
    EXEC sp_executesql @resetId, N'@overrideCheck INT', @overrideCheck = 1;
END TRY
BEGIN CATCH
    EXEC LogError;
END CATCH;
