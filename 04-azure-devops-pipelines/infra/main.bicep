// Sample storage account with secure defaults.
// Compliant with the policies in 01 (Owner tag, HTTPS only, no public blob access).

@description('Where to deploy. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Who owns this resource (required by the policy in project 01).')
param owner string = 'zackaria'

@description('Storage account name: 3-24 lowercase letters and numbers, globally unique.')
@minLength(3)
@maxLength(24)
param storageName string = 'stsec${uniqueString(resourceGroup().id)}'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    Owner: owner
    ManagedBy: 'azure-devops-pipeline'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: { enabled: true }
        file: { enabled: true }
      }
    }
  }
}

output storageAccountName string = storage.name
output storageAccountId string = storage.id
