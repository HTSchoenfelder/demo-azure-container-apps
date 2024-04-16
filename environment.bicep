param location string = resourceGroup().location
@minLength(5)
param name string = resourceGroup().name
param acrName string

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: loganalytics.properties.customerId
        dynamicJsonColumns: false
        sharedKey: listKeys('Microsoft.OperationalInsights/workspaces/${loganalytics.name}', '2020-08-01').primarySharedKey
      }
    }
    zoneRedundant: false
    kedaConfiguration: {}
    daprConfiguration: {}
    customDomainConfiguration: {}
    peerAuthentication: {
      mtls: {
        enabled: false
      }
    }
  }
}

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: name
  location: location
}

resource containerregistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: 'appIdentity'
  location: location
}

resource acrPushRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '8311e382-0749-4cb8-b61a-304f252e45ec'
}

resource acrPushRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, acrName, 'acrPushRoleAssignment')
  scope: containerregistry
  properties: {
    principalId: appIdentity.properties.principalId
    roleDefinitionId: acrPushRoleDefintion.id
    principalType: 'ServicePrincipal'
  }
}

resource runnerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: 'runnerIdentity'
  location: location
}

resource runnerIdentityFederatedCredentials 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-07-31-preview' = {
  name: 'github-runner'
  parent: runnerIdentity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:htschoenfelder/demo-azure-container-apps:environment:production'
  }
}

resource contributorRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, resourceGroup().name, 'contributorRoleAssignment')
  scope: resourceGroup()
  properties: {
    principalId: runnerIdentity.properties.principalId
    roleDefinitionId: contributorRoleDefintion.id
    principalType: 'ServicePrincipal'
  }
}

module acrTaskFrontend './shared/bicep/acr-task.bicep' = {
  name: 'acrTaskFrontend'
  params: {
    location: location
    acrName: acrName
    imageName: 'frontend'   
  }
}

module acrTaskBackend './shared/bicep/acr-task.bicep' = {
  name: 'acrTaskBackend'
  params: {
    location: location
    acrName: acrName
    imageName: 'backend'
  }
}

module acrTaskReverseProxy './shared/bicep/acr-task.bicep' = {
  name: 'acrTaskReverseProxy'
  params: {
    location: location
    acrName: acrName
    imageName: 'reverse-proxy'   
  }
}

module acrTaskGithubRunner './shared/bicep/acr-task.bicep' = {
  name: 'acrTaskGithubRunner'
  params: {
    location: location
    acrName: acrName
    imageName: 'github-runner'   
  }
}
