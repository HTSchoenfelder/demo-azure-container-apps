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
  name: 'reverse-proxy'
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
        external: true
        transport: 'auto'
        targetPort: 80
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
          name: 'reverse-proxy'
          image: '${acr.properties.loginServer}/reverse-proxy:${taskRunId}'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'BACKEND_URL'
              value: 'http://backend'
            }
            {
              name: 'FRONTEND_URL'
              value: 'http://frontend'
            }
          ]          
        }
      ]      
    }
  }
}
