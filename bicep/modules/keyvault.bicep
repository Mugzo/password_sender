@description('The keyvault name.')
param name string

@description('The keyvault location.')
param location string

param tags object

@description('The Workspace ID to store logs')
param workspaceID string

param firstDeployment bool


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

resource generateEncryptionKey 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'generateEncryptionKey'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '10.0'
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'VaultName'
        value: keyVault.name
      }
    ]
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
