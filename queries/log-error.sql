CREATE PROCEDURE LogError AS
BEGIN
    DECLARE @ErrorMessage NVARCHAR(4000),
    @ErrorSeverity INT,
    @ErrorState INT;

    SELECT
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Log error to a table or output it
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END;
