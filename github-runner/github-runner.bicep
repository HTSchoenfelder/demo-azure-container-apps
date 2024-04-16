param location string = resourceGroup().location
param repoOwner string
param repoName string
param taskRunId string
@secure()
param githubPat string
param environmentName string = resourceGroup().name
param appIdentityName string = 'appIdentity'
param runnerIdentityName string = 'runnerIdentity'
param acrName string
param runnerLabel string = 'htschoenfelder-runner'

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

resource runnerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: runnerIdentityName
  scope: resourceGroup()
}

resource githubRunnerJob 'Microsoft.App/jobs@2023-05-01' = {
  name: 'github-runner'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appManagedIdentity.id}': {}
      '${runnerManagedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnv.id
    configuration: {
      eventTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1
        scale: {
          maxExecutions: 10
          minExecutions: 0
          pollingInterval: 30
          rules: [
            {
              name: 'github-runner'
              type: 'github-runner'
              metadata: {
                githubApiURL: 'https://api.github.com'
                owner: repoOwner
                runnerScope: 'repo'
                repos: repoName
                labels: runnerLabel
                targetWorkflowQueueLength: '1'
              }
              auth: [
                {
                  secretRef: 'personal-access-token'
                  triggerParameter: 'personalAccessToken'
                }
              ]
            }
          ]
        }
      }
      registries: [
        {
          identity: appManagedIdentity.id
          server: acr.properties.loginServer
        }
      ]
      secrets: [
        {
          name: 'personal-access-token'
          value: githubPat
        }        
      ]
      replicaTimeout: 1800
      triggerType: 'Event'
      replicaRetryLimit: 1
    }
    template: {
      containers: [
        {
          name: 'github-runner'
          image: '${acr.properties.loginServer}/github-runner:${taskRunId}'
          resources: {
            cpu: 2
            memory: '4Gi'
          }
          env: [
            {
              name: 'PAT_FOR_GITHUB_RUNNER'
              secretRef: 'personal-access-token'
            }
            {
              name: 'REPO_URL'
              value: 'https://github.com/${repoOwner}/${repoName}'
            }
            {
              name: 'REGISTRATION_TOKEN_API_URL'
              value: 'https://api.github.com/repos/${repoOwner}/${repoName}/actions/runners/registration-token'
            }
          ]
        }
      ]
    }
  }
}
