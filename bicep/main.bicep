targetScope = 'subscription'

@description('The prefix for the resources name.')
param prefix string = take(uniqueString(subscription().subscriptionId), 4)

@description('The name of the resource group for the PasswordSender application.')
param name string = 'PasswordSender'

@description('The location of the resources.')
param location string = deployment().location

@description('Tags for the resources.')
param tags object = {
  Environment: 'Production'
  Project: 'PasswordSender'
}

@description('Is it your first deployment (true/false)? If true, a new encryption key will be created.')
param firstDeployment bool

@description('Deploy the code from the bicep deployment.')
param deployCode bool = true


resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-${name}'
  location: location
  tags: tags
}

module logsWorkspace 'modules/logs.bicep' = {
  scope: rg
  name: 'logsWorkspace'
  params: {
    location: location
    name: '${prefix}-logs-${name}'
    tags: tags
  }
}

module umi 'modules/umi.bicep' = {
  scope: rg
  name: 'umi'
  params: {
    location: location
    name: '${prefix}-umi-${name}'
    tags: tags
  }
}

module mongoDB 'modules/mongodb.bicep' = {
  scope: rg
  name: 'mongoDB'
  params: {
    location: location
    name: '${prefix}-mongodb-${toLower(name)}'
    tags: tags
    workspaceID: logsWorkspace.outputs.workspaceID
  }
}

module keyVault 'modules/keyvault.bicep' = {
  scope: rg
  name: 'keyVault'
  params: {
    location: location
    name: '${prefix}-kv-${name}'
    tags: tags
    workspaceID: logsWorkspace.outputs.workspaceID
    firstDeployment: firstDeployment
    umiPrincipalID: umi.outputs.principalID
    mongodb_name: mongoDB.outputs.mongodb_name
  }
}

module web 'modules/web.bicep' = {
  scope: rg
  name: 'web'
  params: {
    keyVaultResourceEndpoint: keyVault.outputs.keyVaultEndpoint
    location: location
    servicePlanName: '${prefix}-plan-${name}'
    tags: tags
    umiClientID: umi.outputs.clientID
    webAppName: '${prefix}-web-${name}'
    workspaceID: logsWorkspace.outputs.workspaceID
    umiID: umi.outputs.umiID
    umiPrincipalID: umi.outputs.principalID
    deployCode: deployCode
  }
  dependsOn: [
    functionApp
  ]
}

module functionApp 'modules/functionapp.bicep' = {
  scope: rg
  name: 'functionApp'
  params: {
    funcName: '${prefix}-functionapp-${toLower(name)}'
    hostingPlanName: '${prefix}-funcplan-${name}'
    keyVaultResourceEndpoint: keyVault.outputs.keyVaultEndpoint
    location: location
    tags: tags
    umiClientID: umi.outputs.clientID
    umiID: umi.outputs.umiID
    workspaceID: logsWorkspace.outputs.workspaceID
  }
}
