import { getApps, initializeApp, cert } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
  FieldPath,
  FieldValue,
  getFirestore,
  type BulkWriter,
  type Firestore,
  type DocumentReference,
  type Query,
  type QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import type { IncomingMessage, ServerResponse } from "node:http";

type Request = IncomingMessage & { body?: unknown };
type Input = Record<string, unknown>;
type DeletionContext = {
  uid: string;
  input: Input;
  db: Firestore;
  auth: ReturnType<typeof getAuth>;
};
type DeletionAction = (context: DeletionContext) => Promise<void>;
type CircleToUnlink = { id: string; memberIds: string[] };

class HttpError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

function getAdmin() {
  if (process.env.VERCEL === "1" && process.env.FIRESTORE_EMULATOR_HOST) {
    throw new HttpError(
      503,
      "Firestore emulator configuration is set in this Vercel deployment. Remove FIRESTORE_EMULATOR_HOST and redeploy.",
    );
  }

  const projectId = process.env.FIREBASE_ADMIN_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_ADMIN_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, "\n");
  if (!projectId || !clientEmail || !privateKey) {
    throw new HttpError(
      503,
      "The account deletion service is not configured. Please contact support.",
    );
  }

  const app =
    getApps()[0] ??
    initializeApp({
      credential: cert({ projectId, clientEmail, privateKey }),
      projectId,
    });

  return { auth: getAuth(app), db: getFirestore(app) };
}

async function parseInput(req: Request): Promise<Input> {
  if (req.body !== undefined) {
    if (typeof req.body === "string") {
      try {
        const body: unknown = JSON.parse(req.body);
        if (body && typeof body === "object" && !Array.isArray(body)) {
          return body as Input;
        }
      } catch {
        throw new HttpError(400, "A valid JSON request body is required.");
      }
      throw new HttpError(400, "A JSON request body is required.");
    }
    if (req.body && typeof req.body === "object" && !Array.isArray(req.body)) {
      return req.body as Input;
    }
    throw new HttpError(400, "A JSON request body is required.");
  }

  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  try {
    const body: unknown = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      throw new Error("Expected an object.");
    }
    return body as Input;
  } catch {
    throw new HttpError(400, "A valid JSON request body is required.");
  }
}

export function deletionHandler(action: DeletionAction) {
  return async (req: Request, res: ServerResponse) => {
    res.setHeader("Cache-Control", "no-store");
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
    res.setHeader("Access-Control-Max-Age", "86400");
    if (req.method === "OPTIONS") {
      res.statusCode = 204;
      res.end();
      return;
    }

    res.setHeader("Content-Type", "application/json");
    if (req.method !== "POST") {
      res.setHeader("Allow", "POST, OPTIONS");
      res.statusCode = 405;
      res.end(JSON.stringify({ success: false, error: "Method not allowed." }));
      return;
    }

    try {
      const authorization = req.headers.authorization;
      const token =
        typeof authorization === "string" && authorization.startsWith("Bearer ")
          ? authorization.slice("Bearer ".length)
          : "";
      if (!token) throw new HttpError(401, "Sign in to continue.");

      const { auth, db } = getAdmin();
      let uid: string;
      try {
        uid = (await auth.verifyIdToken(token, true)).uid;
      } catch {
        throw new HttpError(401, "Your session is invalid. Sign in again.");
      }
      await action({ uid, input: await parseInput(req), db, auth });
      res.statusCode = 200;
      res.end(JSON.stringify({ success: true }));
    } catch (error) {
      if (error instanceof HttpError) {
        res.statusCode = error.status;
        res.end(JSON.stringify({ success: false, error: error.message }));
        return;
      }

      console.error("[datedawn] Admin deletion request failed:", error);
      res.statusCode = 500;
      res.end(
        JSON.stringify({
          success: false,
          error: "Deletion could not be completed. Please retry or contact support.",
        }),
      );
    }
  };
}

function requiredString(input: Input, key: string): string {
  const value = input[key];
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpError(400, `The ${key} field is required.`);
  }
  return value;
}

async function deleteQuery(db: Firestore, query: Query): Promise<void> {
  while (true) {
    const page = await query.limit(400).get();
    if (page.empty) return;
    await deleteReferences(
      db,
      page.docs.map((document) => document.ref),
    );
  }
}

async function finishBulkWriter(
  writer: BulkWriter,
  writes: Promise<unknown>[],
  operation: "delete" | "update" | "write",
): Promise<void> {
  // close() flushes a partial batch; await the individual results afterward.
  const resultsPromise = Promise.allSettled(writes);
  await writer.close();
  const results = await resultsPromise;
  const failures = results.filter((result) => result.status === "rejected");
  if (failures.length > 0) {
    throw new Error(`Failed to ${operation} ${failures.length} Firestore documents.`);
  }
}

async function runInBatches<T>(
  items: T[],
  batchSize: number,
  operation: (item: T) => Promise<void>,
  description: string,
): Promise<void> {
  for (let offset = 0; offset < items.length; offset += batchSize) {
    const results = await Promise.allSettled(
      items.slice(offset, offset + batchSize).map(operation),
    );
    const failures = results.filter(
      (result): result is PromiseRejectedResult => result.status === "rejected",
    );
    if (failures.length > 0) {
      throw new AggregateError(
        failures.map((failure) => failure.reason),
        `Failed to ${description} (${failures.length} operations).`,
      );
    }
  }
}

async function deleteReferences(db: Firestore, references: DocumentReference[]): Promise<void> {
  for (let offset = 0; offset < references.length; offset += 400) {
    const writer = db.bulkWriter();
    const page = references.slice(offset, offset + 400);
    writer.onWriteError((error) => error.failedAttempts < 3);
    const writes = page.map((reference) => writer.delete(reference));
    await finishBulkWriter(writer, writes, "delete");
  }
}

async function deleteEventReferences(db: Firestore, eventId: string): Promise<void> {
  await Promise.all([
    deleteQuery(db, db.collection("responses").where("eventId", "==", eventId)),
    deleteQuery(db, db.collection("invitations").where("eventId", "==", eventId)),
  ]);
}

async function unlinkCircleEvents(
  db: Firestore,
  circleId: string,
  memberIds: string[],
): Promise<void> {
  await unlinkCirclesFromEvents(db, [{ id: circleId, memberIds }]);
}

async function unlinkCirclesFromEvents(
  db: Firestore,
  circlesToUnlink: CircleToUnlink[],
): Promise<void> {
  const circlesById = new Map(circlesToUnlink.map(({ id, memberIds }) => [id, new Set(memberIds)]));
  const circleIdsToUnlink = [...circlesById.keys()];
  if (circleIdsToUnlink.length === 0) return;

  const circleIdsToUnlinkSet = new Set(circleIdsToUnlink);
  const events = db.collection("events");
  const circleQueryBatchSize = 30;
  for (
    let circleOffset = 0;
    circleOffset < circleIdsToUnlink.length;
    circleOffset += circleQueryBatchSize
  ) {
    const targetCircleIds = circleIdsToUnlink.slice(
      circleOffset,
      circleOffset + circleQueryBatchSize,
    );
    while (true) {
      const page = await events
        .where("sharedWithCircleIds", "array-contains-any", targetCircleIds)
        .limit(300)
        .get();
      if (page.empty) break;

      const eventEntries = page.docs.map((event) => {
        const data = event.data();
        const circleIds = Array.isArray(data.sharedWithCircleIds)
          ? data.sharedWithCircleIds.filter((id): id is string => typeof id === "string")
          : [];
        return {
          event,
          data,
          removedCircleIds: [...new Set(circleIds.filter((id) => circleIdsToUnlinkSet.has(id)))],
          otherCircleIds: [...new Set(circleIds.filter((id) => !circleIdsToUnlinkSet.has(id)))],
        };
      });
      const otherCircleIds = [...new Set(eventEntries.flatMap((entry) => entry.otherCircleIds))];
      const membersByCircleId = new Map<string, Set<string>>();

      const circleQueryConcurrency = 5;
      for (
        let offset = 0;
        offset < otherCircleIds.length;
        offset += circleQueryBatchSize * circleQueryConcurrency
      ) {
        const batches: string[][] = [];
        const batchEnd = Math.min(
          offset + circleQueryBatchSize * circleQueryConcurrency,
          otherCircleIds.length,
        );
        for (
          let batchOffset = offset;
          batchOffset < batchEnd;
          batchOffset += circleQueryBatchSize
        ) {
          batches.push(otherCircleIds.slice(batchOffset, batchOffset + circleQueryBatchSize));
        }

        const snapshots = await Promise.all(
          batches.map((batch) =>
            db.collection("circles").where(FieldPath.documentId(), "in", batch).get(),
          ),
        );
        for (const snapshot of snapshots) {
          for (const otherCircle of snapshot.docs) {
            const ids = otherCircle.data().memberIds;
            membersByCircleId.set(
              otherCircle.id,
              new Set(
                Array.isArray(ids) ? ids.filter((id): id is string => typeof id === "string") : [],
              ),
            );
          }
        }
      }

      const writer = db.bulkWriter();
      writer.onWriteError((error) => error.failedAttempts < 3);
      const writes = eventEntries.map(({ event, data, removedCircleIds, otherCircleIds }) => {
        const remainingMembers = new Set<string>();
        for (const otherId of otherCircleIds) {
          for (const memberId of membersByCircleId.get(otherId) ?? []) {
            remainingMembers.add(memberId);
          }
        }

        const circleMemberIds = new Set<string>();
        for (const removedCircleId of removedCircleIds) {
          for (const memberId of circlesById.get(removedCircleId) ?? []) {
            circleMemberIds.add(memberId);
          }
        }
        const removeMembers = [...circleMemberIds].filter(
          (id) => id !== data.createdBy && !remainingMembers.has(id),
        );
        const updates: Record<string, unknown> = {
          sharedWithCircleIds: FieldValue.arrayRemove(...removedCircleIds),
          updatedAt: FieldValue.serverTimestamp(),
        };
        if (removeMembers.length > 0) {
          updates.sharedWithMemberIds = FieldValue.arrayRemove(...removeMembers);
        }
        return writer.update(event.ref, updates);
      });
      await finishBulkWriter(writer, writes, "update");
    }
  }
}

async function deleteOwnedEvent(db: Firestore, event: QueryDocumentSnapshot): Promise<void> {
  await deleteEventReferences(db, event.id);
  await db.recursiveDelete(event.ref);
}

async function deleteAccount({ uid, input, db, auth }: DeletionContext): Promise<void> {
  const confirmation = requiredString(input, "confirmation");
  const user = await auth.getUser(uid);
  const accountEmail = user.email;
  if (!accountEmail) {
    throw new HttpError(400, "Your account has no email address to confirm deletion.");
  }
  if (confirmation !== accountEmail) {
    throw new HttpError(400, "The confirmation value does not match your account email.");
  }

  const ownedEvents = await db.collection("events").where("createdBy", "==", uid).get();
  await runInBatches(
    ownedEvents.docs,
    10,
    (event) => deleteOwnedEvent(db, event),
    "delete owned events",
  );

  const ownedCircles = await db.collection("circles").where("ownerId", "==", uid).get();
  const circlesToUnlink = ownedCircles.docs.map((circle) => {
    const memberIds = circle.data().memberIds;
    return {
      id: circle.id,
      memberIds: Array.isArray(memberIds)
        ? memberIds.filter((id): id is string => typeof id === "string")
        : [],
    };
  });
  await unlinkCirclesFromEvents(db, circlesToUnlink);
  await runInBatches(
    ownedCircles.docs,
    5,
    async (circle) => {
      await deleteQuery(db, db.collection("circle_invitations").where("circleId", "==", circle.id));
      await db.recursiveDelete(circle.ref);
    },
    "delete owned circles",
  );

  const circlesContainingUser = await db
    .collection("circles")
    .where("memberIds", "array-contains", uid)
    .get();
  if (!circlesContainingUser.empty) {
    const writer = db.bulkWriter();
    writer.onWriteError((error) => error.failedAttempts < 3);
    const writes = circlesContainingUser.docs.flatMap((circle) => [
      writer.update(circle.ref, { memberIds: FieldValue.arrayRemove(uid) }),
      writer.delete(circle.ref.collection("members").doc(uid)),
    ]);
    await finishBulkWriter(writer, writes, "write");
  }

  const email = accountEmail.toLowerCase();
  const invitationQueries = [
    db.collection("invitations").where("invitedBy", "==", uid),
    db.collection("circle_invitations").where("invitedBy", "==", uid),
    db.collection("responses").where("recipientId", "==", uid),
  ];
  invitationQueries.push(
    db.collection("invitations").where("inviteeEmail", "==", email),
    db.collection("circle_invitations").where("inviteeEmail", "==", email),
    db.collection("responses").where("responderEmail", "==", email),
  );
  await Promise.all(invitationQueries.map((query) => deleteQuery(db, query)));

  while (true) {
    const sharedEvents = await db
      .collection("events")
      .where("sharedWithMemberIds", "array-contains", uid)
      .limit(300)
      .get();
    if (sharedEvents.empty) break;
    const writer = db.bulkWriter();
    writer.onWriteError((error) => error.failedAttempts < 3);
    const writes = sharedEvents.docs.map((event) =>
      writer.update(event.ref, {
        sharedWithMemberIds: FieldValue.arrayRemove(uid),
        updatedAt: FieldValue.serverTimestamp(),
      }),
    );
    await finishBulkWriter(writer, writes, "update");
  }

  const participantRows = await db.collectionGroup("participants").where("userId", "==", uid).get();
  await deleteReferences(
    db,
    participantRows.docs.map((row) => row.ref),
  );

  await db.recursiveDelete(db.collection("users").doc(uid));
  await auth.deleteUser(uid);
}

async function deleteEvent({ uid, input, db }: DeletionContext): Promise<void> {
  const eventId = requiredString(input, "eventId");
  const eventRef = db.collection("events").doc(eventId);
  const event = await eventRef.get();
  if (!event.exists) throw new HttpError(404, "This event no longer exists.");
  if (event.data()?.createdBy !== uid) {
    throw new HttpError(403, "Only the event owner can delete it.");
  }
  await deleteEventReferences(db, eventId);
  await db.recursiveDelete(eventRef);
}

async function deleteCircle({ uid, input, db }: DeletionContext): Promise<void> {
  const circleId = requiredString(input, "circleId");
  const circleRef = db.collection("circles").doc(circleId);
  const circle = await circleRef.get();
  if (!circle.exists) throw new HttpError(404, "This circle no longer exists.");
  if (circle.data()?.ownerId !== uid) {
    throw new HttpError(403, "Only the circle owner can delete it.");
  }

  const memberIds = circle.data()?.memberIds;
  await unlinkCircleEvents(
    db,
    circleId,
    Array.isArray(memberIds) ? memberIds.filter((id): id is string => typeof id === "string") : [],
  );
  await deleteQuery(db, db.collection("circle_invitations").where("circleId", "==", circleId));
  await db.recursiveDelete(circleRef);
}

export const deleteAccountHandler = deletionHandler(deleteAccount);
export const deleteEventHandler = deletionHandler(deleteEvent);
export const deleteCircleHandler = deletionHandler(deleteCircle);
