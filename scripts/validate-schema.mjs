// Validates supabase/schema.sql with the real PostgreSQL grammar.
//
// A Docker-less syntax check: pgsql-parser wraps the actual Postgres parser,
// so this catches a malformed statement, a stray comma or an unbalanced dollar
// quote without needing a database server. It does NOT catch semantic errors
// such as an out-of-order foreign key reference - those need a live server.
//
// Usage: node scripts/validate-schema.mjs

import { readFileSync } from 'node:fs';
import { parse } from 'pgsql-parser';

const path = new URL('../supabase/schema.sql', import.meta.url);
const sql = readFileSync(path, 'utf8');

// Statements are split on top-level semicolons only. A semicolon inside a
// dollar-quoted block (the `do $$ ... $$` and function bodies) must not split
// the statement, so track the dollar-quote state while scanning.
function splitStatements(text) {
  const out = [];
  let current = '';
  let dollarTag = null;
  let inSingle = false;

  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    const rest = text.slice(i);

    if (dollarTag) {
      if (rest.startsWith(dollarTag)) {
        current += dollarTag;
        i += dollarTag.length - 1;
        dollarTag = null;
        continue;
      }
      current += ch;
      continue;
    }

    // A dollar-quote opener is `$tag$`, where tag is optional.
    const match = rest.match(/^\$[A-Za-z_]*\$/);
    if (match) {
      dollarTag = match[0];
      current += dollarTag;
      i += dollarTag.length - 1;
      continue;
    }

    if (inSingle) {
      current += ch;
      if (ch === "'") inSingle = false;
      continue;
    }
    if (ch === "'") {
      inSingle = true;
      current += ch;
      continue;
    }

    if (ch === ';') {
      out.push(current);
      current = '';
      continue;
    }
    current += ch;
  }
  if (current.trim()) out.push(current);
  return out;
}

// Strip `--` comments so a comment containing a semicolon or a quote cannot
// confuse the splitter above.
function stripLineComments(text) {
  return text
    .split('\n')
    .map((line) => {
      let inSingle = false;
      for (let i = 0; i < line.length; i += 1) {
        const ch = line[i];
        if (inSingle) {
          if (ch === "'") inSingle = false;
          continue;
        }
        if (ch === "'") {
          inSingle = true;
          continue;
        }
        if (ch === '-' && line[i + 1] === '-') return line.slice(0, i);
      }
      return line;
    })
    .join('\n');
}

const cleaned = stripLineComments(sql);
const statements = splitStatements(cleaned).filter((s) => s.trim().length > 0);

let failed = 0;
statements.forEach((statement, index) => {
  try {
    parse(statement);
  } catch (error) {
    failed += 1;
    const firstLine = statement.trim().split('\n')[0].slice(0, 100);
    console.error(`\n[FAIL] statement ${index + 1}: ${firstLine}`);
    console.error(`       ${String(error.message).split('\n')[0]}`);
  }
});

console.log(
  `\nParsed ${statements.length} statements - ` +
  (failed === 0 ? 'all valid SQL.' : `${failed} failed.`),
);
process.exit(failed === 0 ? 0 : 1);
