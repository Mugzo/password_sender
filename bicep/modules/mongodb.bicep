@description('The MongoDB name.')
param name string

@description('The MongoDB location.')
param location string

param tags object

@description('The Workspace ID to store logs')
param workspaceID string


resource mongodb 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: name
  location: location
  tags: tags
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        failoverPriority: 0
        locationName: location
      }
    ]
    backupPolicy: {
      type: 'Continuous'
      continuousModeProperties: {
        tier: 'Continuous7Days'
      }
    }
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    ipRules: []
    minimalTlsVersion: 'Tls12'
    capabilities: [
      {
        name: 'EnableMongo'
      }
      {
        name: 'DisableRateLimitingResponses'
      }
      {
        name: 'EnableServerless'
      }
    ]
    apiProperties: {
      serverVersion: '4.2'
    }
    enableFreeTier: false
    capacity: {
      totalThroughputLimit: 4000
    }
  }
}

resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: mongodb
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
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
        category: 'Requests'
      }
    ]
  }
}

output mongodb_name string = mongodb.name
