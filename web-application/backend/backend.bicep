param location string = resourceGroup().location
param environmentName string = resourceGroup().name
param appIdentityName string = 'appIdentity'
param taskRunId string
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
  scope: resourceGroup()
}

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: environmentName
  scope: resourceGroup()
}

resource appManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: appIdentityName
  scope: resourceGroup()
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'backend'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appManagedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnv.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: false
        transport: 'auto'
        targetPort: 8080
      }
      registries: [
        {
          identity: appManagedIdentity.id
          server: acr.properties.loginServer
        }
      ]      
      secrets: [ ]      
    }
    template: {
      containers: [
        {
          name: 'backend'
          image: '${acr.properties.loginServer}/backend:${taskRunId}'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [ ]          
        }
      ]      
    }
  }
}
