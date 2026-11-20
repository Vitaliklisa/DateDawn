import assert from "node:assert/strict";
import { createServer } from "node:http";
import test from "node:test";

import {
  deleteAccountHandler,
  deleteCircleHandler,
  deleteEventHandler,
} from "../server/deletions.ts";

async function getResponse(handler, method = "GET") {
  const server = createServer((request, response) => {
    void handler(request, response);
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });

  try {
    const address = server.address();
    assert.ok(address && typeof address !== "string");
    return await fetch(`http://127.0.0.1:${address.port}/api`, { method });
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
}

test("account deletion rejects requests without a Firebase token", async () => {
  const response = await getResponse(deleteAccountHandler, "POST");
  assert.equal(response.status, 401);
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  assert.deepEqual(await response.json(), {
    success: false,
    error: "Sign in to continue.",
  });
});

test("account deletion handles CORS preflight requests", async () => {
  const response = await getResponse(deleteAccountHandler, "OPTIONS");
  assert.equal(response.status, 204);
  assert.equal(response.headers.get("access-control-allow-origin"), "*");
  assert.equal(
    response.headers.get("access-control-allow-methods"),
    "POST, OPTIONS",
  );
  assert.equal(
    response.headers.get("access-control-allow-headers"),
    "Authorization, Content-Type",
  );
});

for (const [name, handler] of [
  ["account", deleteAccountHandler],
  ["circle", deleteCircleHandler],
  ["event", deleteEventHandler],
]) {
  test(`${name} deletion handler rejects GET with CORS headers`, async () => {
    const response = await getResponse(handler);
    assert.equal(response.status, 405);
    assert.equal(response.headers.get("access-control-allow-origin"), "*");
    assert.deepEqual(await response.json(), {
      success: false,
      error: "Method not allowed.",
    });
  });
}
