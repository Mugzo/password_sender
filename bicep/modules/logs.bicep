@description('The log analytics workspace name.')
param logsName string

@description('The application Insight name.')
param appInsightName string

@description('The log analytics workspace location.')
param location string

param tags object


resource logsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logsName
  location: location
  tags: tags
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtensionEnablementBlade'
    WorkspaceResourceId: logsWorkspace.id
  }
}

output workspaceID string = logsWorkspace.id
output appInsightName string = appInsights.name
