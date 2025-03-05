param functionName string 
param location string = resourceGroup().location
param storageAccountName string 
param appServicePlanName string
param apiManagementServiceName string = 'nick-urbis-apim'
param tenantId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    tier: 'Dynamic'
    name: 'Y1'
  }
  properties: {
    reserved: true
  }
}

// resource webPubSub 'Microsoft.SignalRService/webPubSub@2024-10-01-preview' = {
//   name: 'urbis-nick-pubsub'
//   location: location
//   sku: {
//     tier: 'Standard'
//     capacity: 1
//     name: 'Standard_S1'
//   }
// }

// resource webPubSubHub 'Microsoft.SignalRService/webPubSub/hubs@2024-10-01-preview' = {
//   parent: webPubSub
//   name: 'urbis-nick-pubsub-hub'
//   properties: {
//     eventHandlers: [
//       {
//         name: 'onConnected'
//         type: 'CloudFunction'
//         cloudFunction: {
//           script: 'onConnected'
//         }
//         urlTemplate:
//       }
//     ]
//   }
// }

resource azAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'urbis-nick-app-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

var azAppInsightsKey = azAppInsights.properties.InstrumentationKey

resource urbisTestFunction 'Microsoft.Web/sites@2024-04-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Node|20' 
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'        
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEB_PUBSUB_CONNECTION_STRING'
          value: 'Endpoint=https://urbis-nick-test.webpubsub.azure.com;AccessKey=G539BqUEQSD5E5OsClqgyurwnSCquOQi4SsYxQlYwb4bPLJMboRLJQQJ99BCAC24pbEXJ3w3AAAAAWPSZNRD;Version=1.0;'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: azAppInsightsKey
        }
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${azAppInsightsKey}'
        }
      ]
    }
  }
}

resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'weiwen.lu@hotmail.com' 
    publisherName: 'Nick Lu'
  }
}

resource urbisTicketsApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  parent: apiManagementService
  name: 'nick-urbis-tickets'
  properties: {
    path: 'tickets'
    protocols: [
      'https'
    ]
    serviceUrl: 'https://${functionName}.azurewebsites.net'
    subscriptionRequired: false
    displayName: 'Tickets API'
  }
}

resource getTicketsApiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: urbisTicketsApi
  name: 'get-tickets'  
  properties: {
    displayName: 'Get Tickets'
    method: 'GET'
    urlTemplate: '/api/get-tickets'
    
    responses: [
      {
        statusCode: 200
        description: 'OK'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

resource createTicketApiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: urbisTicketsApi
  name: 'create-ticket'  
  properties: {
    displayName: 'Create Tickets'
    method: 'POST'
    urlTemplate: '/api/create-ticket'
    
    responses: [
      {
        statusCode: 200
        description: 'OK'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

resource getTokenUrlApiOperation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: urbisTicketsApi
  name: 'negotiate'  
  properties: {
    displayName: 'Get PubSub Token Url'
    method: 'GET'
    urlTemplate: '/api/negotiate'
    
    responses: [
      {
        statusCode: 200
        description: 'OK'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2024-06-01-preview' = {
  parent: apiManagementService
  name: 'urbis-tickets-backend'
  properties: {
    url: 'https://${functionName}.azurewebsites.net'
    protocol: 'http'
  }
}

resource policy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  parent: urbisTicketsApi
  name: 'policy'
  properties: {
    value: format('''
    <policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
            <openid-config url="https://login.microsoftonline.com/{0}/.well-known/openid-configuration" />
            <audiences>
                <audience>api://nick-tasks-api</audience>
            </audiences>
            <required-claims>
                <claim name="appid">
                    <value>8cf2eb08-fd2f-4be3-bb16-1fb929526c56</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <cors allow-credentials="false">
            <allowed-origins>
                <origin>*</origin>
            </allowed-origins>
            <allowed-methods>
                <method>GET</method>
                <method>POST</method>
                <method>PUT</method>
                <method>DELETE</method>
                <method>OPTIONS</method>
            </allowed-methods>
            <allowed-headers>
                <header>*</header>
            </allowed-headers>
        </cors>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <set-header name="Access-Control-Allow-Origin" exists-action="append">
            <value>*</value>
        </set-header>
        <set-header name="Access-Control-Allow-Methods" exists-action="override">
            <value>GET</value>
            <value>PUT</value>
            <value>POST</value>
            <value>DELETE</value>
            <value>OPTION</value>
        </set-header>
        <set-header name="Access-Control-Allow-Headers" exists-action="override">
            <value>Content-Type</value>
        </set-header>
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
    ''', tenantId)
  }
}

resource createTicketPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2024-06-01-preview' = {
  parent: createTicketApiOperation
  name: 'policy'
  properties: {
    value: format('''
    <policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="403" failed-validation-error-message="No sufficient privillege.">
            <openid-config url="https://login.microsoftonline.com/{0}/.well-known/openid-configuration" />
            <audiences>
                <audience>api://nick-tasks-api</audience>
            </audiences>
            <required-claims>
                <claim name="role">
                    <value>admin</value>
                </claim>
            </required-claims>
        </validate-jwt>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
       <base /> 
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
    ''', tenantId)
  }
}

