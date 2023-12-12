-- Declare user variables
DECLARE @custom_password NVARCHAR(256) = N'REPLACE_PASSWORD';
DECLARE @first_name VARCHAR(30) = 'EDS';
DECLARE @middle_name VARCHAR(30) = 'Service';
DECLARE @last_name VARCHAR(30) = 'Account';
DECLARE @email_address VARCHAR(50) = N'REPLACE_EMAIL';

-- Declare a table variable to store user information
DECLARE @users
    TABLE (
   [ID] INT IDENTITY(1, 1) ,
   [FirstName] VARCHAR(30) ,
   [MiddleName] VARCHAR(30),
   [LastName] VARCHAR(30)  ,
   [Email] VARCHAR(50)
);

-- Insert a sample user into the @users table
INSERT INTO @users
   (FirstName, MiddleName, LastName, Email)
SELECT DISTINCT *
FROM (
             VALUES
      (@first_name, @middle_name, @last_name, @email_address)
          ) X (FirstName, MiddleName, LastName, Email);

-- Declare variables for application and role information
DECLARE @ApplicationId UNIQUEIDENTIFIER                       ,
@ApplicationName NVARCHAR(256)                                ,
@RoleId UNIQUEIDENTIFIER                                      ,
@CurrentTimeUTC DATETIME                                      ,
@DefaultDateTime DATETIME = CONVERT(DATETIME, '17540101', 112);

-- Fetch application information based on the application name 'SchoolTool'
SELECT @ApplicationId =   ApplicationId ,
   @ApplicationName = ApplicationName
FROM aspnet_Applications aa
WHERE aa.ApplicationName = 'SchoolTool';

-- Get the current date and time
SELECT @CurrentTimeUTC = GETDATE();

-- Fetch the RoleId for 'Super User' from the UserType table
SELECT @RoleId = ar.RoleId
FROM aspnet_Roles ar
   JOIN UserType ut ON ar.RoleName = ut.TEXT
WHERE ut.TEXT LIKE '%Super%User' AND
   ut.Active = 1;

-- If RoleId is NULL, generate a new unique identifier
SELECT @RoleId = ISNULL(@RoleId, NEWID());

-- Insert a new role into the aspnet_Roles table if it doesn't already exist
INSERT INTO aspnet_Roles
   (ApplicationId, RoleId, RoleName, LoweredRoleName, Description)
SELECT @ApplicationId [ApplicationId]  ,
   @RoleId        [RoleId]         ,
   ut.TEXT        [RoleName]       ,
   LOWER(ut.TEXT) [LoweredRoleName],
   NULL           [Description]
FROM UserType ut
WHERE ut.TEXT LIKE '%Super%User' AND
   ut.Active = 1 AND
   NOT EXISTS (
             SELECT 1
   FROM aspnet_Roles ar
   WHERE ar.ApplicationId = @ApplicationId AND
      ar.RoleName = ut.TEXT
          );

-- Declare variables for loop iteration and user information
DECLARE @i INT             ,
@m INT                     ,
@firstname VARCHAR(30)     ,
@middlename VARCHAR(30)    ,
@lastname VARCHAR(30)      ,
@Email VARCHAR(50)         ,
@PersonId INT              ,
@Password NVARCHAR(128)    ,
@PasswordSalt NVARCHAR(128),
@UserId UNIQUEIDENTIFIER;

-- Get the minimum and maximum ID values from the @users table
SELECT @i = MIN(ID),
   @m = MAX(ID)
FROM @users u;

-- Loop through each user in the @users table
WHILE @i <= @m BEGIN
   -- Fetch user details for the current iteration
   SELECT @firstname =  FirstName ,
      @middlename = MiddleName,
      @lastname =   LastName  ,
      @Email =      Email
   FROM @users u
   WHERE u.ID = @i;

   -- Update the Email and ModifiedOn fields in the [Person] table
   UPDATE p
      SET Email = @Email       ,
          ModifiedOn = GETDATE()
     FROM [Person] p
    WHERE p.FirstName = @firstname AND
      p.LastName = @lastname AND
      ISNULL(p.Email, '') <> ISNULL(@Email, '');

   -- Insert a new person into the [Person] table if they don't already exist
   INSERT INTO Person
      (
      [Active] ,
      [FirstName] ,
      [MiddleName] ,
      [LastName] ,
      [Email] ,
      [CreatedOn] ,
      [ModifiedOn] ,
      [IsRegisteredVoter] ,
      [IsHispanic] ,
      [IsHomeless] ,
      [IsMigrant] ,
      [IsImmigrant] ,
      [IsNeglectedOrDelinquent],
      [UniversalContactID] ,
      [GUID_ID]
      )
   SELECT CAST(1      AS BIT),
      @firstname         ,
      @middlename        ,
      @lastname          ,
      @Email             ,
      GETDATE()          ,
      GETDATE()          ,
      CAST(0      AS BIT),
      CAST(0      AS BIT),
      CAST(0      AS BIT),
      CAST(0      AS BIT),
      CAST(0      AS BIT),
      CAST(0      AS BIT),
      ''                 ,
      NEWID()
   WHERE NOT EXISTS (
             SELECT 1
   FROM [Person] p
   WHERE p.FirstName = @firstname AND
      p.LastName = @lastname
          );

   -- Fetch the PersonId for the newly inserted person
   SELECT TOP 1
      @PersonId = ID
   FROM Person p
   WHERE p.FirstName = @firstname AND
      p.LastName = @lastname AND
      p.Email = @Email;

   -- Print the PersonId for debugging purposes
   PRINT @PersonId;

   -- Insert a new faculty member into the [Faculty] table if they don't already exist
   INSERT INTO [Faculty]
      (FacultyID, Person_ID, Active, UniversalFacultyID, LastModifiedOn)
   SELECT ''     ,
      @PersonId        ,
      CAST(1    AS BIT),
      ''               ,
      GETDATE()
   WHERE NOT EXISTS (
             SELECT 1
   FROM Faculty f
   WHERE f.Person_ID = @PersonId
          );

   -- Update the Active and GroupIdp_ID fields in the [User] table
   UPDATE u
      SET Active = CAST(1 AS BIT)            ,
          GroupIdp_ID = ISNULL(GroupIdp_ID, 0)
     FROM [User] u
    WHERE u.Person_ID = @PersonId AND
      u.[Login] = @Email;

   -- Insert a new user into the [User] table if they don't already exist
   INSERT INTO [User]
      (
      LOGIN ,
      Active ,
      Person_ID ,
      LastModifiedOn,
      GroupIdp_ID
      )
   SELECT @Email    [Login],
      CAST(1    AS BIT),
      @PersonId        ,
      GETDATE()        ,
      0
   WHERE NOT EXISTS (
             SELECT 1
   FROM [User] u
   WHERE u.Login = @Email AND
      u.Person_ID = @PersonId
          );

   -- Fetch the UserId for the user from the dbo.aspnet_Users table
   SELECT @UserId = NULL;

   SELECT @UserId = UserId
   FROM dbo.aspnet_Users
   WHERE LOWER(@Email) = LoweredUserName AND
      @ApplicationId = ApplicationId;

   -- Create a new user in the dbo.aspnet_Users table if they don't already exist
   IF (@UserId IS NULL) BEGIN
      EXEC [dbo].[aspnet_Users_CreateUser] @ApplicationId,
@Email                                                                        ,
0                                                                             ,
@CurrentTimeUTC                                                               ,
@UserId OUTPUT;

   END;

   -- Generate a new password salt
   SELECT @PasswordSalt = CAST(N'' AS XML).value ('xs:base64Binary(sql:column("bin"))', 'NVARCHAR(128)')
   FROM (
             SELECT CONVERT(VARBINARY(128), NEWID()) bin
          ) a;

   -- Generate a new hashed password
   SELECT @Password = CAST(N'' AS XML).value ('xs:base64Binary(sql:column("HASH"))', 'NVARCHAR(128)')
   FROM (
             SELECT HASHBYTES(
                    'SHA1'                                                                                                                                                        ,
                    CAST(N'' AS XML).value ('xs:base64Binary(sql:variable("@PasswordSalt"))', 'VARBINARY(MAX)') + CAST(ISNULL(@custom_password, N'$cr@Mbl32o22!') AS VARBINARY(MAX))
                    ) [Hash]
          ) a;

   -- Update the password for the user in the dbo.aspnet_Membership table if they already exist
   IF EXISTS (
   SELECT 1
   FROM dbo.aspnet_Membership
   WHERE dbo.aspnet_Membership.ApplicationId = @ApplicationId AND
      dbo.aspnet_Membership.UserId = @UserId
) BEGIN
      EXEC [dbo].[aspnet_Membership_SetPassword] @ApplicationName,
@Email                                                             ,
@Password                                                          ,
@PasswordSalt                                                      ,
@CurrentTimeUTC                                                    ,
1;

   END;

   -- Insert a new user into the dbo.aspnet_Membership table if they don't already exist
   IF NOT EXISTS (
   SELECT 1
   FROM dbo.aspnet_Membership
   WHERE dbo.aspnet_Membership.ApplicationId = @ApplicationId AND
      dbo.aspnet_Membership.UserId = @UserId
) BEGIN
      INSERT INTO dbo.aspnet_Membership
         (
         ApplicationId ,
         UserId ,
         Password ,
         PasswordSalt ,
         Email ,
         LoweredEmail ,
         PasswordQuestion ,
         PasswordAnswer ,
         PasswordFormat ,
         IsApproved ,
         IsLockedOut ,
         CreateDate ,
         LastLoginDate ,
         LastPasswordChangedDate ,
         LastLockoutDate ,
         FailedPasswordAttemptCount ,
         FailedPasswordAttemptWindowStart ,
         FailedPasswordAnswerAttemptCount ,
         FailedPasswordAnswerAttemptWindowStart
         )
      VALUES
         (
            @ApplicationId  ,
            @UserId         ,
            @Password       ,
            @PasswordSalt   ,
            @Email          ,
            LOWER(@Email)   ,
            NULL            ,
            NULL            ,
            1               ,
            1               ,
            0               ,
            @CurrentTimeUTC ,
            @CurrentTimeUTC ,
            @CurrentTimeUTC ,
            @DefaultDateTime,
            0               ,
            @DefaultDateTime,
            0               ,
            @DefaultDateTime
          );

   END;

   -- Insert the user into the aspnet_UsersInRoles table
   INSERT INTO aspnet_UsersInRoles
      (UserId, RoleId)
   SELECT @UserId,
      @RoleId
   WHERE NOT EXISTS (
             SELECT 1
   FROM aspnet_UsersInRoles auir
   WHERE auir.RoleId = @RoleId AND
      auir.UserId = @UserId
          );

   -- Increment the loop counter
   SELECT @i = MIN(ID)
   FROM @users u
   WHERE u.ID > @i;

END
-- Add CNYRIC Staff to all building levels
PRINT '--Adding All Building Levels for Super Users--';

-- Insert faculty members into the FacultyBuildingSchoolLevel table
INSERT INTO FacultyBuildingSchoolLevel
   (Building_SchoolLevel_ID, Faculty_ID, StartDate)
SELECT bsl.ID,
   f.ID            ,
   GETDATE()
FROM Building_SchoolLevel bsl,
   Faculty f
   JOIN Person p ON f.Person_ID = p.ID
   JOIN @users u ON p.FirstName = u.FirstName AND
      p.LastName = u.LastName
WHERE NOT EXISTS (
             SELECT 1
FROM FacultyBuildingSchoolLevel
WHERE f.ID = FacultyBuildingSchoolLevel.Faculty_ID AND
   bsl.ID = FacultyBuildingSchoolLevel.Building_SchoolLevel_ID AND
   GETDATE() BETWEEN FacultyBuildingSchoolLevel.StartDate AND ISNULL(FacultyBuildingSchoolLevel.EndDate, GETDATE())
          );

-- Update CNYRIC Staff to be active faculty
PRINT '--Activating CNYRIC Faculty';

-- Update the Active field in the Faculty table
UPDATE Faculty
      SET [Active] = CAST(1 AS BIT)
     FROM Faculty f
   JOIN Person p ON f.Person_ID = p.ID
   JOIN @users u ON p.FirstName = u.FirstName AND
      p.LastName = u.LastName
    WHERE f.Person_ID = p.ID;
