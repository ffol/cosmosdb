targetScope = 'resourceGroup'

@description('Name of the Azure Cosmos DB for Mongo vCore cluster.')
@minLength(3)
@maxLength(40)
param mongoClusterName string

@description('MongoDB server version. Must be 8.0 for this deployment.')
@allowed([
  '8.0'
])
param mongoServerVersion string

@description('Mongo cluster compute tier (for example: M30, M40, M50).')
param mongoClusterTier string

@description('Storage size in GiB for the cluster.')
@minValue(32)
param mongoStorageSizeGb int

@description('Storage type for the cluster.')
@allowed([
  'PremiumSSD'
])
param mongoStorageType string

@description('Number of shards. Keep 1 to match the requested topology.')
@allowed([
  1
])
param mongoShardCount int

@description('High availability mode for the cluster.')
@allowed([
  'SameZone'
  'ZoneRedundantPreferred'
])
param mongoHighAvailabilityTargetMode string

@description('Subnet resource ID where the Private Endpoint NIC is created.')
param privateEndpointSubnetResourceId string

@description('Resource ID of the existing private DNS zone used for Mongo cluster private endpoint resolution (hub subscription supported).')
param privateDnsZoneResourceId string

@description('Name of the private endpoint resource.')
param privateEndpointName string

@description('Name of the private DNS zone group attached to the private endpoint.')
param privateDnsZoneGroupName string

@description('Name of the private DNS zone config item in the zone group.')
param privateDnsZoneConfigName string

@description('Private Link group ID for Azure Cosmos DB Mongo vCore.')
param privateLinkGroupId string

@description('Object ID (GUID) of the Entra principal to create as the Mongo root user.')
param entraPrincipalObjectId string

@description('Principal type for the Entra identity provider user.')
@allowed([
  'user'
  'servicePrincipal'
])
param entraPrincipalType string

@description('URI of the existing Key Vault key used for CMK encryption (format: https://kv-name.vault.azure.net/keys/key-name).')
param cmkKeyUrl string

@description('Resource ID of an existing user-assigned managed identity that has access to the CMK in Key Vault.')
param cmkUserAssignedIdentityResourceId string

resource mongoCluster 'Microsoft.DocumentDB/mongoClusters@2025-09-01' = {
  name: mongoClusterName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${cmkUserAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    serverVersion: mongoServerVersion
    publicNetworkAccess: 'Disabled'
    authConfig: {
      allowedModes: [
        'MicrosoftEntraID'
      ]
    }
    compute: {
      tier: mongoClusterTier
    }
    sharding: {
      shardCount: mongoShardCount
    }
    highAvailability: {
      targetMode: mongoHighAvailabilityTargetMode
    }
    storage: {
      sizeGb: mongoStorageSizeGb
      type: mongoStorageType
    }
    encryption: {
      customerManagedKeyEncryption: {
        keyEncryptionKeyUrl: cmkKeyUrl
        keyEncryptionKeyIdentity: {
          identityType: 'UserAssignedIdentity'
          userAssignedIdentityResourceId: cmkUserAssignedIdentityResourceId
        }
      }
    }
  }
}

resource mongoUser 'Microsoft.DocumentDB/mongoClusters/users@2025-09-01' = {
  name: entraPrincipalObjectId
  parent: mongoCluster
  properties: {
    identityProvider: {
      type: 'MicrosoftEntraID'
      properties: {
        principalType: entraPrincipalType
      }
    }
    roles: [
      {
        db: 'admin'
        role: 'root'
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-10-01' = {
  name: privateEndpointName
  location: resourceGroup().location
  properties: {
    subnet: {
      id: privateEndpointSubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-pls'
        properties: {
          privateLinkServiceId: mongoCluster.id
          groupIds: [
            privateLinkGroupId
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-10-01' = {
  name: privateDnsZoneGroupName
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneConfigName
        properties: {
          privateDnsZoneId: privateDnsZoneResourceId
        }
      }
    ]
  }
}

output mongoClusterResourceId string = mongoCluster.id
output mongoUserResourceId string = mongoUser.id
output privateEndpointResourceId string = privateEndpoint.id
