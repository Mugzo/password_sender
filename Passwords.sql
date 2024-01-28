CREATE TABLE [dbo].Passwords
(
    password_id varchar(22) PRIMARY KEY,
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    expire_days INT NOT NULL,
    expire_views INT NOT NULL,
    viewer_deletable BIT NOT NULL,
    views INT NOT NULL,
    expire_on DATETIME NOT NULL,
    passphrase_hash varchar(64),
    password varchar(184) NOT NULL
);

-- This is using the default UMI name. Modify if not using defaults.
CREATE USER [prod-umi-PasswordSender] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [prod-umi-PasswordSender];
ALTER ROLE db_datawriter ADD MEMBER [prod-umi-PasswordSender];
ALTER ROLE db_ddladmin ADD MEMBER [prod-umi-PasswordSender];

GO