# Azure Cosmos DB for MongoDB vCore (Private Networking + CMK + Entra-Only Auth) - Bicep

This folder deploys Azure Cosmos DB for MongoDB vCore with:
- Existing target resource group (subscription-scope entrypoint)
- MongoDB server version `8.0`
- Single shard (`shardCount = 1`)
- High availability enabled (`targetMode = ZoneRedundantPreferred` by default)
- Microsoft Entra-only authentication (`allowedModes = ['MicrosoftEntraID']`)
- Entra principal provisioned as Mongo `root` user (admin DB scope)
- Customer-managed key (CMK) encryption via existing Key Vault key + user-assigned identity
- Private Endpoint in workload resource group
- Private DNS zone integration using an existing DNS zone resource ID (hub subscription supported)
- Public network access disabled

## Files
- `main.bicep`: Subscription-scope entrypoint targeting an existing workload resource group.
- `cosmosdb.rg.bicep`: Resource-group-scope module with Mongo cluster, Entra user, private endpoint, and DNS zone group.
- `main.bicepparam`: Parameter values (anonymized placeholders for public sharing).

## Prerequisites
- Azure CLI installed and logged in.
- Access to deploy at subscription scope.
- Existing resources:
  - Workload resource group (same one used for workload deployments)
  - Subnet for private endpoint placement
  - Centralized private DNS zone for Mongo vCore private endpoint
  - Key Vault key for CMK
  - User-assigned managed identity with key permissions on the CMK key
  - Entra principal object ID (user or service principal) to grant Mongo root access

## Update Parameters Before Deployment
Edit `main.bicepparam` and replace placeholder values:
- `workloadSubscriptionId`
- `hubSubscriptionId`
- `workloadResourceGroupName`
- `hubResourceGroupName`
- `privateEndpointSubnetResourceId`
- `privateDnsZoneResourceId`
- `mongoClusterTier` (example: `M30`)
- `entraPrincipalObjectId`
- `entraPrincipalType` (`user` or `servicePrincipal`)
- `cmkKeyUrl`
- `cmkUserAssignedIdentityResourceId`

## How to get Entra Object ID
For a user principal:

```powershell
az ad user show --id <user-upn> --query id -o tsv
```

For a service principal:

```powershell
az ad sp show --id <app-id-or-sp-id> --query id -o tsv
```

## Deploy
Set your preferred Azure region in `$location` (example: `swedencentral`):

```powershell
$name = "docdb-mongo-" + (Get-Date -Format "yyyyMMddHHmmss")
$location = "swedencentral"
az deployment sub create --name $name --location $location --template-file ./main.bicep --parameters ./main.bicepparam
```

## Optional: What-If
Preview changes before applying:

```powershell
$name = "docdb-mongo-" + (Get-Date -Format "yyyyMMddHHmmss")
$location = "swedencentral"
az deployment sub what-if --name "$name-wi" --location $location --template-file ./main.bicep --parameters ./main.bicepparam
```

## Notes
- The private link group ID defaults to `MongoCluster`.
- The Entra Mongo user is created with role `root` on DB `admin`.
- CMK uses `identityType = UserAssignedIdentity` and the specified UAI resource ID.
- Cluster name must match `^[a-z0-9]+(-[a-z0-9]+)*` and be 3-40 characters.
