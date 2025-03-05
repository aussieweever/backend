import { app } from "@azure/functions";
import { createTicket } from "./functions/create-ticket";
import { getTickets } from "./functions/get-tickets";

app.setup({
  enableHttpStream: true,
});
