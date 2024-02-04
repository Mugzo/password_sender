// Used with MongoDB

@description('The function app name.')
param funcName string

@description('The function app location.')
param location string

param tags object

@description('The Workspace ID to store logs')
param workspaceID string

@description('The hosting plan name.')
param hostingPlanName string

@description('The User Managed Identity Client ID')
param umiClientID string

@description('The User Managed Identity ID.')
param umiID string

param keyVaultResourceEndpoint string

@description('The URI to download the Github repository.')
param codeURI string = 'https://github.com/Mugzo/password_sender/archive/refs/heads/main.zip'


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
      ]
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      linuxFxVersion: 'Python|3.11'
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
    publicNetworkAccess: 'Disabled'
    httpsOnly: true
    serverFarmId: hostingPlan.id
  }
}

resource pythonCodeDeployment 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'pythonCodeDeployment'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umiID}': {}
    }
  }
  properties: {
    azPowerShellVersion: '11.0'
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
        name: 'webAppName'
        value: functionApp.name
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: umiClientID
      }
    ]
  
    scriptContent: '''
      Invoke-WebRequest -Uri $env:codeURI -OutFile ./code.zip
      Expand-Archive ./code.zip
      Compress-Archive -Path ./code/password_sender-main/functionapp/* -DestinationPath ./function.zip
      Connect-AzAccount -Identity
      $app = Get-AzWebApp -ResourceGroupName $env:resourceGroupName -Name $env:webAppName
      Publish-AzWebApp -WebApp $app -ArchivePath ./function.zip -Force
    '''
  }
}
