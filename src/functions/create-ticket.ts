import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from "@azure/functions";

export async function createTicket(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log(`Http function processed request for url "${request.url}"`);

  const body = request.body;
  return {
    body: JSON.stringify({
      ...body,
      id: "3",
    }),
  };
}

app.http("create-ticket", {
  methods: ["POST"],
  authLevel: "anonymous",
  handler: createTicket,
});
