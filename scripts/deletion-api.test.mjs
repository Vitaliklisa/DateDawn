import assert from "node:assert/strict";
import { createServer } from "node:http";
import test from "node:test";

import deleteAccountHandler from "../api/delete-account.ts";
import deleteCircleHandler from "../api/delete-circle.ts";
import deleteEventHandler from "../api/delete-event.ts";

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
  assert.deepEqual(await response.json(), {
    success: false,
    error: "Sign in to continue.",
  });
});

for (const [name, handler] of [
  ["account", deleteAccountHandler],
  ["circle", deleteCircleHandler],
  ["event", deleteEventHandler],
]) {
  test(`Vercel ${name} deletion handler loads and rejects GET`, async () => {
    const response = await getResponse(handler);
    assert.equal(response.status, 405);
    assert.deepEqual(await response.json(), {
      success: false,
      error: "Method not allowed.",
    });
  });
}
