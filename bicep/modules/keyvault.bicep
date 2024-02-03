@description('The keyvault name.')
param name string

@description('The keyvault location.')
param location string

param tags object

@description('The Workspace ID to store logs')
param workspaceID string

param firstDeployment bool

@description('The User Managed Identity Object (principal) ID.')
param umiPrincipalID string

@description('The MongoDB name')
param mongodb_name string

resource mongodb 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' existing = {
  name: mongodb_name
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 30
    publicNetworkAccess: 'enabled' 
  }
}

@description('This is the built-in Key Vault Secrets User.')
resource keyVaultSecretsUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, umiPrincipalID, keyVaultSecretsUserRoleDefinition.id)
  properties: {
    principalId: umiPrincipalID
    roleDefinitionId: keyVaultSecretsUserRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

resource generateEncryptionKey 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'generateEncryptionKey'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '11.0'
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
  
    scriptContent: '''
      $key = [Convert]::ToBase64String((1..32|%{[byte](Get-Random -Max 256)}))
      $DeploymentScriptOutputs = @{}
      $DeploymentScriptOutputs['key'] = $key
    '''
  }
}

resource keySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (firstDeployment) {
  parent: keyVault
  name: 'PasswordEncryptionKey'
  properties: {
    value: generateEncryptionKey.properties.outputs.key
  }
}

resource mongodbConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'MongoDBConnectionString'
  properties: {
    value: mongodb.listConnectionStrings().connectionStrings[0].connectionString
  }
}

resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVault
  name: '${name}-logs'
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
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
        category: 'AllMetrics'
      }
    ]
  }
}


output keyVaultEndpoint string = keyVault.properties.vaultUri
