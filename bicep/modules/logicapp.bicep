// The logic app is used when using SQL as the database.

@description('The logic app name.')
param logicAppName string

@description('The SQL Connection name.')
param sqlConnectionName string

@description('The logic app location.')
param location string

param tags object

@description('The Workspace ID to store logs')
param workspaceID string

@description('The User Managed Identity ID.')
param umiID string

param sqlServerName string

param sqlDatabaseName string


resource connectionSql 'Microsoft.Web/connections@2016-06-01' = {
  name: sqlConnectionName
  location:location
  tags: tags
  properties: {
    displayName: sqlConnectionName
    parameterValueSet: {
      name: 'oauthMI'
      values: {}
    }
    api: {
      name: 'sql'
      displayName: 'SQL Server'
      description: 'Microsoft SQL Server is a relational database management system developed by Microsoft. Connect to SQL Server to manage data. You can perform various actions such as create, update, get, and delete on rows in a table.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1670/1.0.1670.3526/sql/icon.png'
      brandColor: '#ba141a'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: 'https://management.azure.com:443/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().id}/providers/Microsoft.Web/connections/${sqlConnectionName}/extensions/proxy/testconnection?api-version=2018-07-01-preview'
        method: 'get'
      }
    ]
    testRequests: [
      {
        body: {
          request: {
            method: 'get'
            path: 'testconnection'
          }
        }
        inputParameters: [
          {
            path: 'body.properties.workflowReference.id'
            type: 'string'
            description: 'The workflow reference resource id.'
          }
        ]
        requestUri: 'https://management.azure.com:443/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().id}/providers/Microsoft.Web/connections/${sqlConnectionName}/dynamicInvoke?api-version=2018-07-01-preview'
        method: 'POST'
      }
    ]
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umiID}': {}
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        'Execute_a_SQL_query_(V2)': {
          inputs: {
            body: {
              query: 'DELETE FROM Passwords WHERE expire_on < CONVERT(DATETIME2,GETDATE())'
            }
            host: {
              connection: {
                name: connectionSql.id
              }
            }
            method: 'post'
            path: '/v2/datasets/${uriComponent(uriComponent(sqlServerName))},${uriComponent(uriComponent(sqlDatabaseName))}/query/sql'
          }
          runAfter: {}
          type: 'ApiConnection'
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          evaluatedRecurrence: {
            frequency: 'Day'
            interval: 1
            startTime: '2024-01-12T07:00:00Z'
            timeZone: 'Eastern Standard Time'
          }
          recurrence: {
            frequency: 'Day'
            interval: 1
            startTime: '2024-01-12T07:00:00Z'
            timeZone: 'Eastern Standard Time'
          }
          type: 'Recurrence'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          sql: {
            connectionId: connectionSql.id
            connectionName: sqlConnectionName
            connectionProperties: {
              authentication: {
                identity: umiID
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
          }
        }
      }
    }
  }
}

resource logicAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: logicApp
  name: '${logicAppName}-logs'
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceId: workspaceID
    logs: [
      {
        category: 'WorkflowRuntime'
        categoryGroup: null
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
