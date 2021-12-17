// ------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ------------------------------------------------------------

const express = require("express");
const bodyParser = require("body-parser");
require("isomorphic-fetch");

const app = express();
app.use(bodyParser.json());

const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const daprHost = process.env.DAPR_HTTP_HOST || "localhost";
const stateStoreName = `statestore`;
const stateUrl = `http://${daprHost}:${daprPort}/v1.0/state/${stateStoreName}`;
const port = 3000;

app.get("/order", async (_req, res) => {
  const res = await fetch(`${stateUrl}/order`);
  if (!res.ok) throw new Error("Could not get state.");
  const orders = await res.text();
  res.send(orders);
});

app.get("/echo", () => {
    
} )

app.post("/neworder", (req, res) => {
  const data = req.body.data;
  const orderId = data.orderId;
  console.log("Got a new order! Order ID: " + orderId);

  const state = [
    {
      key: "order",
      value: data,
    },
  ];

  const res = await fetch(stateUrl, {
    method: "POST",
    body: JSON.stringify(state),
    headers: {
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) throw new Error("Failed to persist state.");
  console.log("Successfully persisted state.");
  res.status(200).send();
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).send({ message: error.message });
});

app.listen(port, () => console.log(`Node App listening on port ${port}!`));
