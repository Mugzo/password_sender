targetScope = 'subscription'

@description('The prefix for the resources name.')
param prefix string = 'prod'

@description('The name of the resource group for the PasswordSender application.')
param name string = 'PasswordSender'

@description('The location of the resources.')
param location string = deployment().location

@description('Tags for the resources.')
param tags object = {
  Environment: 'Production'
  Project: 'PasswordSender'
}

@description('Is it your first deployment (true/false)? If true, SQL Database Table and PasswordEncryptionKey will be created else not.')
param firstDeployment bool

@description('The UPN of the user that will be administrator of the SQL server.')
param sqlServerAdminUPN string

@description('The Object ID of the user that will be administrator of the SQL server.')
param sqlServerAdminID string


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
  }
}

module sql 'modules/sql.bicep' = {
  scope: rg
  name: 'sql'
  params: {
    location: location
    sqlDbName: '${prefix}-sqlsrv-${name}'
    sqlServerAdminID: sqlServerAdminID
    sqlServerAdminUPN: sqlServerAdminUPN
    sqlServerName: '${prefix}-sqldb-${name}'
    tags: tags
    workspaceID: logsWorkspace.outputs.workspaceID
    firstDeployment: firstDeployment
    umiName: umi.outputs.umiName
  }
}

module web 'modules/web.bicep' = {
  scope: rg
  name: 'web'
  params: {
    keyVaultResourceEndpoint: keyVault.outputs.keyVaultEndpoint
    location: location
    servicePlanName: '${prefix}-plan-${name}'
    sqlDatabaseName: sql.outputs.sqlDatabaseName
    sqlServerName: sql.outputs.sqlServerName
    tags: tags
    umiClientID: umi.outputs.clientID
    webAppName: '${prefix}-web-${name}'
    workspaceID: logsWorkspace.outputs.workspaceID
    umiID: umi.outputs.umiID
  }
}
