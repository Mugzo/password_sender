@description('The log analytics workspace name.')
param name string

@description('The log analytics workspace location.')
param location string

param tags object


resource logsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
}

output workspaceID string = logsWorkspace.id
