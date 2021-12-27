// ------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ------------------------------------------------------------

import express from "express";
import bodyParser from "body-parser";
import fetch from "isomorphic-fetch";
import { env } from "process";

// DAPR configuration
/** Dapr is listening by default at localhost:3500 */
const DAPR_HOST = env.MPROC_DAPR_HTTP_HOST || "localhost";
const DAPR_PORT = env.MPROC_DAPR_HTTP_PORT || 3500;
/** This is the name of the Dapr binding used */
const STORE_NAME = `statestore`;
const STORE_URL = `http://${DAPR_HOST}:${DAPR_PORT}/v1.0/state/${STORE_NAME}`;
/** Port the web server should be listening to */
const APP_PORT = 3000;

/**
 * EXPRESS ROUTER
 */

const app = express();
app.use(bodyParser.json());
/**
 * Retrieves and sends back the last recorded state
 */
app.get("/order", async (_req, response) => {
  const res = await fetch(`${STORE_URL}/order`);
  if (!res.ok) throw new Error("Could not get state.");
  const orders = await res.text();
  response.send(orders);
});

/**
 * Persists a new state using Dapr
 */
app.post("/neworder", async (req, response) => {
  const data = req.body.data;
  const orderId = data.orderId;
  console.log("Got a new order! Order ID: " + orderId);

  const state = [
    {
      key: "order",
      value: data,
    },
  ];

  const res = await fetch(STORE_URL, {
    method: "POST",
    body: JSON.stringify(state),
    headers: {
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) throw new Error("Failed to persist state.");
  console.log("Successfully persisted state.");
  response.status(200).send();
});

/**
 * Echo endpoint, use for benchmarking latency
 */
app.get("/echo", () => {
  response.send(Math.random());
});

/**
 * Global error handler
 */
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).send({ message: error.message });
});

app.listen(APP_PORT, () =>
  console.log(`Node App listening on port ${APP_PORT}!`)
);
