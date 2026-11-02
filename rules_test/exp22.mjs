import { readFileSync, writeFileSync } from 'node:fs';
let s = readFileSync('rules_test/exp.rules', 'utf8');
const which = process.argv[2];

const body = {
      r1: `      return (requestIsRoleChange() && isAdmin(eventId) && roleChangeAllowed(eventId, userId))
        || (!requestIsRoleChange() && !affectsRole() && isAdmin(eventId));`,
      r2: `      return (requestIsRoleChange() && isAdmin(eventId) && roleChangeAllowed(eventId, userId))
        || (!requestIsRoleChange() && !affectsRole() && (isAdmin(eventId) || isEventOwner(eventId)));`,
      r3: `      return (requestIsRoleChange() && (isAdmin(eventId) || isEventOwner(eventId)) && roleChangeAllowed(eventId, userId))
        || (!requestIsRoleChange() && !affectsRole());`,
      r4: `      return (requestIsRoleChange() && (isAdmin(eventId) || isEventOwner(eventId)) && rank(request.resource.data.get('role','')) <= myRank(eventId))
        || (!requestIsRoleChange() && !affectsRole() && (isAdmin(eventId) || isEventOwner(eventId)));`,
      r5: `      return (requestIsRoleChange() && (isAdmin(eventId) || isEventOwner(eventId)) && (targetUserId != uid()))
        || (!requestIsRoleChange() && !affectsRole() && (isAdmin(eventId) || isEventOwner(eventId)));`,
};

s = s.replace(/function participantUpdateAllowed\(eventId, targetUserId\) \{[\s\S]*?\n    \}/, `function participantUpdateAllowed(eventId, targetUserId) {\n${body[which]}\n    }`);
writeFileSync('rules_test/exp.rules', s);
console.log('wrote', which);
