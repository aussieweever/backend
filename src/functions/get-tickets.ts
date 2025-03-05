import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from "@azure/functions";
import { WebPubSubServiceClient } from "@azure/web-pubsub";

interface Ticket {
  id: string;
  title: string;
  priority: string;
  description: string;
}
export async function getTickets(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log(`Http function processed request for url "${request.url}"`);

  const tickets: Ticket[] = [
    {
      id: "1",
      title: "Ticket 1",
      priority: "High",
      description: "This is ticket 1",
    },
    {
      id: "2",
      title: "Ticket 2",
      priority: "Low",
      description: "This is ticket 2",
    },
  ];

  const service = new WebPubSubServiceClient(
    process.env.WEB_PUBSUB_CONNECTION_STRING,
    "demo"
  );
  console.log("Sending message to all clients");
  await service.sendToAll(
    "Get tickets called at: " + new Date().toISOString(),
    {
      contentType: "text/plain",
    }
  );

  return {
    body: JSON.stringify(tickets),
  };
}

app.http("get-tickets", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: getTickets,
});
