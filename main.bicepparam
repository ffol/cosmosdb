using './main.bicep'

var workloadSubscriptionId = '06bfa713-9d6d-44a9-8643-b39e003e136b'
var hubSubscriptionId = '06bfa713-9d6d-44a9-8643-b39e003e136b'

var workloadResourceGroupName = 'rg-0612251532-zta'
var hubResourceGroupName = 'rg-0612251532-zta'

var vnetName = 'vnet-4stweewz5g5bs'
var subnetName = 'pe-subnet'

var mongoClusterPrefix = 'docdb-mongo'
var deploymentEnvironment = 'dev'
var mongoClusterInstance = '001'

var privateEndpointPrefix = 'pep'

var keyVaultName = 'kv-4stweewz5g5bs'
var cmkKeyName = 'key-pg-flex-dev-001'
var cmkUMI = 'uai-testvm4stweewz5'

param resourceGroupName = workloadResourceGroupName
param mongoClusterName = '${mongoClusterPrefix}-${deploymentEnvironment}-${mongoClusterInstance}'
param mongoClusterTier = 'M30'
param mongoStorageType = 'PremiumSSD'
param privateEndpointName = '${privateEndpointPrefix}-${mongoClusterName}'

// Replace with a valid subnet resource ID for private endpoint placement.
param privateEndpointSubnetResourceId = '/subscriptions/${workloadSubscriptionId}/resourceGroups/${workloadResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'

// Existing centralized private DNS zone resource ID (hub subscription supported).
param privateDnsZoneResourceId = '/subscriptions/${hubSubscriptionId}/resourceGroups/${hubResourceGroupName}/providers/Microsoft.Network/privateDnsZones/privatelink.mongocluster.cosmos.azure.com'

param privateLinkGroupId = 'MongoCluster'

// Entra principal (user or service principal object ID) to provision as Mongo root user.
param entraPrincipalObjectId = '0400cd35-323a-4bf5-b17b-12ed7da01630'
param entraPrincipalType = 'user'

// Existing Key Vault key URI (without key version segment for Mongo vCore CMK API).
param cmkKeyUrl = 'https://${keyVaultName}.vault.azure.net/keys/${cmkKeyName}'

// Existing user-assigned managed identity with key permissions.
param cmkUserAssignedIdentityResourceId = '/subscriptions/${workloadSubscriptionId}/resourceGroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${cmkUMI}'
