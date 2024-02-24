// Used with MongoDB

@description('The function app name.')
param funcName string

@description('The hosting plan name.')
param hostingPlanName string

@description('The storage account name.')
param storageName string

@description('The function app location.')
param location string

param tags object

@description('The User Managed Identity Client ID')
param umiClientID string

@description('The User Managed Identity ID.')
param umiID string

@description('The User Managed Identity Object (principal) ID.')
param umiPrincipalID string

param keyVaultResourceEndpoint string

@description('The URI to download the Github repository.')
param codeURI string = 'https://github.com/sam-lapointe/password_sender/archive/refs/heads/main.zip'

param appInsightName string


resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    accessTier: 'Hot'
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
    }
    dnsEndpointType: 'Standard'
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
           enabled: true
        }
        table: {
          enabled: true
        }
        queue: {
          enabled: true
        }
      }
      requireInfrastructureEncryption: false
    }
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  tags: tags
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
  kind: 'linux'
  properties: {
    targetWorkerSizeId: 0
    targetWorkerCount: 1
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: funcName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umiID}': {}
    }
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: umiClientID
        }
        {
          name: 'AZURE_KEYVAULT_RESOURCEENDPOINT'
          value: keyVaultResourceEndpoint
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      linuxFxVersion: 'Python|3.11'
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    serverFarmId: hostingPlan.id
  }
}

@description('This is the built-in Website Contributor role.')
resource websiteContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'de139f84-1756-47ae-9be6-808fbbe84772'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionApp.id, umiPrincipalID, websiteContributorRoleDefinition.id)
  properties: {
    principalId: umiPrincipalID
    roleDefinitionId: websiteContributorRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

resource pythonCodeDeployment 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'functionCodeDeployment'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umiID}': {}
    }
  }
  properties: {
    azCliVersion: '2.9.1'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT1H'

    environmentVariables: [
      {
        name: 'codeURI'
        value: codeURI
      }
      {
        name: 'resourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'functionAppName'
        value: functionApp.name
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: umiClientID
      }
    ]
  
    scriptContent: '''
      curl -L $codeURI -o ./code.zip
      unzip ./code.zip -d ./code
      zip -r -j ./function.zip ./code/password_sender-main/functionapp/
      az login --identity
      az functionapp deployment source config-zip -g $resourceGroupName -n $functionAppName --src ./function.zip --build-remote true
    '''
  }
}
