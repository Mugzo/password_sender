@description('The user managed identity name.')
param name string

@description('The user managed identity name.')
param location string

param tags object


resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: name
  location: location
  tags: tags
}

output clientID string = umi.properties.clientId
output principalID string = umi.properties.principalId
output umiID string = umi.id
output umiName string = umi.name
