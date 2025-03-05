# Backend Demo

This is a backend demo, integrated with Azure Entra ID, Azure Function App, Azure Web Pubsub Service and APIM. The repo is generated uising the `azure function core tool`.

## Infrastructure

The `scripts/deploy.sh` does the deployment job, which create a resource group first, and then create all the resources defined in the `bicep/main.bicep`.

### Infrastructure created using Bicep

- Storage Accoount
- Service Plan
- Application Insight
- One Azure function with 3 http triggers
- APIM + Tickets API
- API operations point to 3 http triggers of the azure function
- Common inbound/outbound/jwt policies for all tickets API
- JWT validator to check role claim for the `create-ticket` API.

### Infrastructure created manually

- The Azure Web Pubsub Service & related hub
- Backend and Frontend App registration
- API scope, permission and roles configuration

### Scripts

Under the directory scripts, there are 3 files (except the `deploy.sh`) were created for app registration and scope definition (mainly because I couldn't find a way to create them using Bicep)
However, I found azure cli has some limitations at this stage and it cannot set the `oauth2Permissions`. I believe the powershell should work but I did it all manually (not sure if powershell can work on Mac now).

### Source files

The `create-ticket.ts` and the `get-tickets.ts` are 2 functions do some dummy works, as the purpose is just to demonstrate the integration with APIM.

The `get-ws-url.ts` is a function to generate the websocket access url for the client.

### APIM

With the current setup, all the requests need to pass the jwt validation, which is only to validate the appid claim in my case.
The `create-ticket` has another jwt validation step ot verify the role claim, this is to simulate the RBAC we may need in future. I didn't make it work in this demo, as the basic tier of Entra ID doesn't support custom role setup.
