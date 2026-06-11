targetScope = 'subscription'

@description('Name of the existing resource group where Azure Cosmos DB for Mongo vCore and Private Endpoint are deployed.')
param resourceGroupName string

@description('Name of the Azure Cosmos DB for Mongo vCore cluster.')
@minLength(3)
@maxLength(40)
param mongoClusterName string

@description('MongoDB server version. Must be 8.0 for this deployment.')
@allowed([
  '8.0'
])
param mongoServerVersion string = '8.0'

@description('Mongo cluster compute tier (for example: M30, M40, M50).')
param mongoClusterTier string = 'M30'

@description('Storage size in GiB for the cluster.')
@minValue(32)
param mongoStorageSizeGb int = 128

@description('Storage type for the cluster.')
@allowed([
  'PremiumSSD'
])
param mongoStorageType string = 'PremiumSSD'

@description('Number of shards. Keep 1 to match the requested topology.')
@allowed([
  1
])
param mongoShardCount int = 1

@description('High availability mode for the cluster.')
@allowed([
  'SameZone'
  'ZoneRedundantPreferred'
])
param mongoHighAvailabilityTargetMode string = 'ZoneRedundantPreferred'

@description('Subnet resource ID where the Private Endpoint NIC is created.')
param privateEndpointSubnetResourceId string

@description('Resource ID of the existing private DNS zone used for Mongo cluster private endpoint resolution (hub subscription supported).')
param privateDnsZoneResourceId string

@description('Name of the private endpoint resource.')
param privateEndpointName string

@description('Name of the private DNS zone group attached to the private endpoint.')
param privateDnsZoneGroupName string = 'default'

@description('Name of the private DNS zone config item in the zone group.')
param privateDnsZoneConfigName string = 'mongodb-dns'

@description('Private Link group ID for Azure Cosmos DB Mongo vCore.')
param privateLinkGroupId string = 'MongoCluster'

@description('Object ID (GUID) of the Entra principal to create as the Mongo root user.')
param entraPrincipalObjectId string = deployer().objectId

@description('Principal type for the Entra identity provider user.')
@allowed([
  'user'
  'servicePrincipal'
])
param entraPrincipalType string = 'user'

@description('URI of the existing Key Vault key used for CMK encryption (format: https://kv-name.vault.azure.net/keys/key-name).')
param cmkKeyUrl string

@description('Resource ID of an existing user-assigned managed identity that has access to the CMK in Key Vault.')
param cmkUserAssignedIdentityResourceId string

resource targetRg 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: resourceGroupName
}

module mongoRgDeployment './cosmosdb.rg.bicep' = {
  scope: targetRg
  params: {
    mongoClusterName: mongoClusterName
    mongoServerVersion: mongoServerVersion
    mongoClusterTier: mongoClusterTier
    mongoStorageSizeGb: mongoStorageSizeGb
    mongoStorageType: mongoStorageType
    mongoShardCount: mongoShardCount
    mongoHighAvailabilityTargetMode: mongoHighAvailabilityTargetMode
    privateEndpointSubnetResourceId: privateEndpointSubnetResourceId
    privateDnsZoneResourceId: privateDnsZoneResourceId
    privateEndpointName: privateEndpointName
    privateDnsZoneGroupName: privateDnsZoneGroupName
    privateDnsZoneConfigName: privateDnsZoneConfigName
    privateLinkGroupId: privateLinkGroupId
    entraPrincipalObjectId: entraPrincipalObjectId
    entraPrincipalType: entraPrincipalType
    cmkKeyUrl: cmkKeyUrl
    cmkUserAssignedIdentityResourceId: cmkUserAssignedIdentityResourceId
  }
}

output mongoClusterResourceId string = mongoRgDeployment.outputs.mongoClusterResourceId
output mongoUserResourceId string = mongoRgDeployment.outputs.mongoUserResourceId
output privateEndpointResourceId string = mongoRgDeployment.outputs.privateEndpointResourceId
