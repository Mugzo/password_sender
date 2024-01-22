@description('The SQL server name.')
param sqlServerName string

@description('The SQL database name.')
param sqlDbName string

@description('The location of the resources.')
param location string

param tags object

@description('The Workspace ID to store logs')
param workspaceID string

@description('The UPN of the user that will be administrator of the SQL server.')
param sqlServerAdminUPN string

@description('The Object ID of the user that will be administrator of the SQL server.')
param sqlServerAdminID string

@description('The name of the User Managed Identity.')
param umiName string 

param firstDeployment bool


resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: sqlServerAdminUPN
      principalType: 'User'
      sid: sqlServerAdminID
      tenantId: tenant().tenantId
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// This is not recommanded in a production environment for security reasons. This allow ALL azure IPs.
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDbName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
  properties: {
    autoPauseDelay: 60
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    zoneRedundant: false
    readScale: 'Disabled'
    highAvailabilityReplicaCount: 0
    minCapacity: json('0.5')
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
    availabilityZone: 'NoPreference'
    useFreeLimit: true
    freeLimitExhaustionBehavior: 'AutoPause'
  }
}

resource dbDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sqlDatabase
  name: '${sqlDbName}-logs'
  properties: {
    logAnalyticsDestinationType: null
    workspaceId: workspaceID
    logs: [
      {
        category: null
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        timeGrain: null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
        category: 'Basic'
      }
      {
        timeGrain: null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
        category: 'InstanceAndAppAdvanced'
      }
      {
        timeGrain: null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
        category: 'WorkloadManagement'
      }
    ]
  }
}

resource setupDatabase 'Microsoft.Resources/deploymentScripts@2023-08-01' = if (firstDeployment) {
  name: 'setupDatabase'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '10.0'
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'identityName'
        value: umiName
      }
      {
        name: 'sqlServerName'
        value: sqlServer.name
      }
      {
        name: 'sqlDatabaseName'
        value: sqlDatabase.name
      }
    ]
    scriptContent: '''
    $test = systeminfo
    echo $test
    '''
  }
}


output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
