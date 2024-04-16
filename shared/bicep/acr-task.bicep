param location string = resourceGroup().location
param encodedTaskContent string = 'dmVyc2lvbjogdjEuMS4wCnN0ZXBzOgogIC0gYnVpbGQ6IC0tdGFnICRSZWdpc3RyeS97ey5WYWx1ZXMuaW1hZ2VOYW1lfX06JElEIC0tdGFnICRSZWdpc3RyeS97ey5WYWx1ZXMuaW1hZ2VOYW1lfX06bGF0ZXN0IC4KICAtIHB1c2g6IAogICAgLSAkUmVnaXN0cnkve3suVmFsdWVzLmltYWdlTmFtZX19OiRJRAogICAgLSAkUmVnaXN0cnkve3suVmFsdWVzLmltYWdlTmFtZX19OmxhdGVzdA=='
param imageName string
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource task 'Microsoft.ContainerRegistry/registries/tasks@2019-04-01' = {
  parent: acr
  name: imageName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    credentials: {
      customRegistries: {
        '${acrName}.azurecr.io': {
          identity: '[system]'
        }
      }
      sourceRegistry: {
        loginMode: 'None'
      }
    }
    platform: {
      os: 'Linux'
    }
    step: {
      type: 'EncodedTask'
      encodedTaskContent: encodedTaskContent
      values: [
        {
          name: 'imageName'
          value: imageName
        }
      ]
    }
    trigger: {
      baseImageTrigger: null
      sourceTriggers: null
      timerTriggers: null
    }
  }
}

resource acrPushRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '8311e382-0749-4cb8-b61a-304f252e45ec'
}

resource taskRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(task.id, 'taskRoleAssignment')
  scope: acr
  properties: {
    principalId: task.identity.principalId
    roleDefinitionId: acrPushRoleDefintion.id
    principalType: 'ServicePrincipal'
  }
}
