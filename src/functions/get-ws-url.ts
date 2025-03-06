import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from "@azure/functions";
import { WebPubSubServiceClient } from "@azure/web-pubsub";

export async function getTokenUrl(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log(`Http function processed request for url "${request.url}"`);

  const service = new WebPubSubServiceClient(
    process.env.WEB_PUBSUB_CONNECTION_STRING,
    "demo" // dynamic hub name, ideally shoudl be created using Bicep
  );
  const token = await service.getClientAccessToken({
    roles: ["webpubsub.joinLeaveGroup.demo"], // this role is required to allow the client to join the group
  });
  return {
    body: JSON.stringify({
      url: token.url,
    }),
  };
}

app.http("negotiate", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: getTokenUrl,
});
