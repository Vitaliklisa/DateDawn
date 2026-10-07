-- ============================================================================
--  Date Dawn - Supabase schema (Firebase Auth, Supabase data)
-- ============================================================================
--
--  HOW THIS FITS THE APP
--  ---------------------
--  Firebase Authentication is the only identity provider. Supabase stores the
--  data. The two are joined by the Firebase ID token: the Flutter client hands
--  it to Supabase on every request (see the `accessToken` callback in
--  `lib/main.dart`), Supabase verifies it against the Firebase project
--  registered under Authentication -> Third-Party Auth, and exposes the
--  Firebase uid as `auth.uid()`.
--
--  Every table below therefore keys on the FIREBASE uid, and every policy is
--  written against `auth.uid()`. There is no `x-user-id` header and no
--  client-supplied identity anywhere: the uid in `auth.uid()` is read from a
--  signature-verified JWT and cannot be forged.
--
--  BEFORE THIS SCHEMA WILL WORK
--  ----------------------------
--  1. Supabase dashboard -> Authentication -> Third-Party Auth -> add Firebase,
--     with the Firebase project id (`datedawn`).
--  2. Firebase must stamp `role: 'authenticated'` on every token, or Supabase
--     assigns the `anon` Postgres role and every policy below denies. This is
--     done by a blocking Auth function - see `firebase/functions/index.js`.
--     Existing accounts need the one-off backfill in
--     `firebase/functions/backfill-role.js`.
--  3. Run this file in the Supabase SQL editor.
--
--  Run the whole file top to bottom; it is idempotent.
-- ============================================================================


-- ============================================================================
--  PART 1 - TABLES
-- ============================================================================

-- ---------------------------------------------------------------------------
--  events - one countdown
-- ---------------------------------------------------------------------------
--  A countdown: a title, an optional note, the moment, and who created it.
--
--  `deleted_at` is a soft delete, carried over from the Firestore design so an
--  accidental delete stays recoverable and participant history is not
--  orphaned. Every read filters `deleted_at is null`.
create table if not exists public.events (
  id            uuid primary key default gen_random_uuid(),
  title         text not null check (char_length(title) between 1 and 80),
  description   text not null default '' check (char_length(description) <= 280),
  at            timestamptz not null,
  created_by    text not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

comment on table public.events is
  'One countdown. created_by is a Firebase uid. Soft-deleted via deleted_at.';

create index if not exists events_created_by_idx
  on public.events (created_by) where deleted_at is null;
create index if not exists events_at_idx
  on public.events (at) where deleted_at is null;


-- ---------------------------------------------------------------------------
--  event_participants - who can see one countdown
-- ---------------------------------------------------------------------------
--  `user_id` is a Firebase uid. `invite_status` mirrors the old Firestore
--  field so the UI keeps its pending / accepted / rejected distinction; a
--  couple-circle share writes `accepted` directly, an invitation writes
--  `pending`.
create table if not exists public.event_participants (
  event_id      uuid not null references public.events (id) on delete cascade,
  user_id       text not null,
  email         text not null default '',
  role          text not null default 'viewer'
                check (role in ('admin', 'editor', 'viewer')),
  invite_status text not null default 'pending'
                check (invite_status in ('pending', 'accepted', 'rejected')),
  display_name  text,
  photo_url     text,
  joined_at     timestamptz not null default now(),
  primary key (event_id, user_id)
);

comment on table public.event_participants is
  'Who can see a countdown, and with what role. user_id is a Firebase uid.';

create index if not exists event_participants_user_idx
  on public.event_participants (user_id);


-- ---------------------------------------------------------------------------
--  event_circles - which circles a countdown is shared with
-- ---------------------------------------------------------------------------
--  event_notes - messages left on a countdown
-- ---------------------------------------------------------------------------
create table if not exists public.event_notes (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid not null references public.events (id) on delete cascade,
  user_id     text not null,
  text        text not null check (char_length(text) between 1 and 2000),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists event_notes_event_idx
  on public.event_notes (event_id, created_at);


-- ---------------------------------------------------------------------------
--  circles - a standing group
-- ---------------------------------------------------------------------------
--  A standing group you count down with. `owner_id` is a Firebase uid.
create table if not exists public.circles (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 60),
  description text not null default '' check (char_length(description) <= 280),
  owner_id    text not null,
  emoji       text,
  is_couple   boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists circles_owner_idx on public.circles (owner_id);


-- ---------------------------------------------------------------------------
--  circle_members - who is in which circle
-- ---------------------------------------------------------------------------
--  The primary key makes "join" idempotent, which matters because accepting an
--  invitation can be retried after a dropped connection.
create table if not exists public.circle_members (
  circle_id    uuid not null references public.circles (id) on delete cascade,
  user_id      text not null,
  email        text not null default '',
  display_name text,
  photo_url    text,
  role         text not null default 'member'
               check (role in ('owner', 'admin', 'member')),
  joined_at    timestamptz not null default now(),
  primary key (circle_id, user_id)
);

comment on table public.circle_members is
  'Circle membership. user_id is a Firebase uid; owner is role = owner.';

create index if not exists circle_members_user_idx
  on public.circle_members (user_id);


-- ---------------------------------------------------------------------------
--  event_circles - which circles a countdown is shared with
-- ---------------------------------------------------------------------------
--  Declared after BOTH `events` and `circles` exist: it references each, so
--  Postgres rejects it if it is created before either.
--
--  A join table rather than an array so the visibility rule is a plain EXISTS
--  and does not need one index per array element.
create table if not exists public.event_circles (
  event_id   uuid not null references public.events (id) on delete cascade,
  circle_id  uuid not null references public.circles (id) on delete cascade,
  primary key (event_id, circle_id)
);

create index if not exists event_circles_circle_idx
  on public.event_circles (circle_id);


-- ---------------------------------------------------------------------------
--  invitations - invite one person to one countdown
-- ---------------------------------------------------------------------------
--  `invitee_email` is what the invitation is addressed to; `invitee_id` is
--  filled in once that email is known to have an account, so the invitee can
--  read their own row by uid. Answering is one-way: pending -> accepted.
create table if not exists public.invitations (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references public.events (id) on delete cascade,
  invited_by    text not null,
  invitee_email text not null,
  invitee_id    text,
  role          text not null default 'viewer'
                check (role in ('admin', 'editor', 'viewer')),
  status        text not null default 'pending'
                check (status in ('pending', 'accepted', 'rejected')),
  event_title   text not null default '',
  created_at    timestamptz not null default now(),
  expires_at    timestamptz not null default now() + interval '30 days'
);

create index if not exists invitations_email_idx
  on public.invitations (lower(invitee_email)) where status = 'pending';
create index if not exists invitations_invitee_idx
  on public.invitations (invitee_id) where status = 'pending';
create index if not exists invitations_event_idx
  on public.invitations (event_id);


-- ---------------------------------------------------------------------------
--  circle_invitations - invite one person to one circle
-- ---------------------------------------------------------------------------
create table if not exists public.circle_invitations (
  id              uuid primary key default gen_random_uuid(),
  circle_id       uuid not null references public.circles (id) on delete cascade,
  invited_by      text not null,
  invited_by_name text,
  invitee_email   text not null,
  invitee_id      text,
  circle_name     text not null default '',
  is_couple       boolean not null default false,
  role            text not null default 'member',
  status          text not null default 'pending'
                  check (status in ('pending', 'accepted', 'rejected')),
  created_at      timestamptz not null default now(),
  expires_at      timestamptz not null default now() + interval '30 days'
);

create index if not exists circle_invitations_email_idx
  on public.circle_invitations (lower(invitee_email)) where status = 'pending';
create index if not exists circle_invitations_invitee_idx
  on public.circle_invitations (invitee_id) where status = 'pending';


-- ---------------------------------------------------------------------------
--  responses - "your friend joined / declined"
-- ---------------------------------------------------------------------------
create table if not exists public.responses (
  id              uuid primary key default gen_random_uuid(),
  recipient_id    text not null,
  event_id        uuid,
  event_title     text not null default 'your countdown',
  responder_email text not null default '',
  responder_name  text,
  accepted        boolean not null,
  is_read         boolean not null default false,
  responded_at    timestamptz not null default now()
);

create index if not exists responses_recipient_idx
  on public.responses (recipient_id, responded_at desc);




-- ---------------------------------------------------------------------------
--  profiles - public half of an account
-- ---------------------------------------------------------------------------
--  `id` is the Firebase uid. `email` is stored lowercased so an invitation can
--  be turned into an account without reading the auth record.
create table if not exists public.profiles (
  id          text primary key,
  email       text,
  username    text,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is
  'Public profile per account. id = Firebase uid. email is lowercased.';

-- Email lookups happen on every invite, so index it. Partial: rows written
-- before this column existed have no email and are not worth indexing.
create index if not exists profiles_email_idx
  on public.profiles (lower(email)) where email is not null;


-- ---------------------------------------------------------------------------
--  user_settings - appearance
-- ---------------------------------------------------------------------------
--  `theme_mode` is constrained rather than free text: the client maps the
--  string straight onto Flutter's ThemeMode, so an unexpected value would
--  crash the parse. The check makes that impossible at the source.
create table if not exists public.user_settings (
  user_id     text primary key,
  theme_mode  text not null default 'system'
              check (theme_mode in ('light', 'dark', 'system')),
  updated_at  timestamptz not null default now()
);


-- ---------------------------------------------------------------------------
--  notifications - the in-app inbox
-- ---------------------------------------------------------------------------
--  `user_id` is the Firebase uid of the recipient. The `type` column lets the
--  UI pick an icon without parsing the body text.
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     text not null,
  title       text not null check (char_length(title) between 1 and 120),
  body        text not null default '' check (char_length(body) <= 500),
  type        text not null default 'system'
              check (type in ('invitation', 'circle', 'system', 'reminder')),
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);


-- ============================================================================
--  PART 2 - HELPER FUNCTIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
--  updated_at maintenance
-- ---------------------------------------------------------------------------
--  Set by the database rather than trusted from the client, so a wrong device
--  clock cannot corrupt the ordering.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists user_settings_touch_updated_at on public.user_settings;
create trigger user_settings_touch_updated_at
  before update on public.user_settings
  for each row execute function public.touch_updated_at();

drop trigger if exists events_touch_updated_at on public.events;
create trigger events_touch_updated_at
  before update on public.events
  for each row execute function public.touch_updated_at();

drop trigger if exists event_notes_touch_updated_at on public.event_notes;
create trigger event_notes_touch_updated_at
  before update on public.event_notes
  for each row execute function public.touch_updated_at();


-- ---------------------------------------------------------------------------
--  Membership / permission helpers
-- ---------------------------------------------------------------------------
--  SECURITY DEFINER so a policy on one table can consult another without
--  recursing into that table's own policy. Each fixes `search_path`, which is
--  what makes a definer function safe to expose.

-- Is the caller a member of this circle?
create or replace function public.is_circle_member(p_circle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.circle_members m
    where m.circle_id = p_circle_id
      and m.user_id = auth.uid()::text
  );
$$;

-- Can the caller see this countdown at all?
-- Creator, an accepted participant, or a member of a circle it is shared with.
create or replace function public.can_read_event(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    where e.id = p_event_id
      and e.deleted_at is null
      and (
        e.created_by = auth.uid()::text
        or exists (
          select 1 from public.event_participants p
          where p.event_id = e.id
            and p.user_id = auth.uid()::text
            and p.invite_status = 'accepted'
        )
        or exists (
          select 1
          from public.event_circles ec
          join public.circle_members m on m.circle_id = ec.circle_id
          where ec.event_id = e.id
            and m.user_id = auth.uid()::text
        )
      )
  );
$$;

-- Can the caller edit this countdown (rename / reschedule / share)?
create or replace function public.can_edit_event(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    where e.id = p_event_id
      and (
        e.created_by = auth.uid()::text
        or exists (
          select 1 from public.event_participants p
          where p.event_id = e.id
            and p.user_id = auth.uid()::text
            and p.invite_status = 'accepted'
            and p.role in ('admin', 'editor')
        )
      )
  );
$$;

-- Can the caller manage this countdown (invite / delete)?
create or replace function public.can_manage_event(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.events e
    where e.id = p_event_id
      and (
        e.created_by = auth.uid()::text
        or exists (
          select 1 from public.event_participants p
          where p.event_id = e.id
            and p.user_id = auth.uid()::text
            and p.invite_status = 'accepted'
            and p.role = 'admin'
        )
      )
  );
$$;


-- ============================================================================
--  PART 3 - ROW LEVEL SECURITY
-- ============================================================================
--
--  Every policy is written against `auth.uid()`, which is the Firebase uid
--  carried in the verified ID token. `(select auth.uid())` is used throughout
--  rather than a bare `auth.uid()`: Postgres treats the wrapped form as a
--  constant for the duration of the statement and evaluates it once, instead
--  of once per row.
--
--  Deliberately NO `iss` / `aud` checks: hosted Supabase verifies the token
--  against the project registered under Third-Party Auth, so those claims are
--  already validated.
-- ============================================================================

alter table public.events             enable row level security;
alter table public.event_participants enable row level security;
alter table public.event_circles      enable row level security;
alter table public.event_notes        enable row level security;
alter table public.circles            enable row level security;
alter table public.circle_members     enable row level security;
alter table public.invitations        enable row level security;
alter table public.circle_invitations enable row level security;
alter table public.responses          enable row level security;
alter table public.profiles           enable row level security;
alter table public.user_settings      enable row level security;
alter table public.notifications      enable row level security;

-- ---------------------------------------------------------------------------
--  events
-- ---------------------------------------------------------------------------
drop policy if exists "events select visible" on public.events;
create policy "events select visible"
  on public.events for select to authenticated
  using (
    created_by = (select auth.uid())::text
    or public.can_read_event(id)
  );

-- The creator is always the caller: a client cannot create a countdown on
-- somebody else's behalf.
drop policy if exists "events insert own" on public.events;
create policy "events insert own"
  on public.events for insert to authenticated
  with check (created_by = (select auth.uid())::text);

drop policy if exists "events update editor" on public.events;
create policy "events update editor"
  on public.events for update to authenticated
  using (public.can_edit_event(id))
  with check (public.can_edit_event(id));

drop policy if exists "events delete owner" on public.events;
create policy "events delete owner"
  on public.events for delete to authenticated
  using (created_by = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  event_participants
-- ---------------------------------------------------------------------------
drop policy if exists "participants select visible" on public.event_participants;
create policy "participants select visible"
  on public.event_participants for select to authenticated
  using (
    user_id = (select auth.uid())::text
    or public.can_read_event(event_id)
  );

-- You may add yourself (accepting an invitation), or someone who can manage
-- the countdown may add anyone. The creator seeds their own admin row at
-- creation time, which the `user_id = auth.uid()` branch covers.
drop policy if exists "participants insert self or manager" on public.event_participants;
create policy "participants insert self or manager"
  on public.event_participants for insert to authenticated
  with check (
    user_id = (select auth.uid())::text
    or public.can_manage_event(event_id)
  );

-- An invitee may flip their OWN row pending -> accepted. Managers may change
-- anything.
drop policy if exists "participants update self or manager" on public.event_participants;
create policy "participants update self or manager"
  on public.event_participants for update to authenticated
  using (
    user_id = (select auth.uid())::text
    or public.can_manage_event(event_id)
  )
  with check (
    user_id = (select auth.uid())::text
    or public.can_manage_event(event_id)
  );

drop policy if exists "participants delete self or manager" on public.event_participants;
create policy "participants delete self or manager"
  on public.event_participants for delete to authenticated
  using (
    user_id = (select auth.uid())::text
    or public.can_manage_event(event_id)
  );

-- ---------------------------------------------------------------------------
--  event_circles
-- ---------------------------------------------------------------------------
drop policy if exists "event_circles select visible" on public.event_circles;
create policy "event_circles select visible"
  on public.event_circles for select to authenticated
  using (public.can_read_event(event_id));

drop policy if exists "event_circles write editor" on public.event_circles;
create policy "event_circles write editor"
  on public.event_circles for all to authenticated
  using (public.can_edit_event(event_id))
  with check (public.can_edit_event(event_id));

-- ---------------------------------------------------------------------------
--  event_notes
-- ---------------------------------------------------------------------------
drop policy if exists "notes select visible" on public.event_notes;
create policy "notes select visible"
  on public.event_notes for select to authenticated
  using (public.can_read_event(event_id));

drop policy if exists "notes insert participant" on public.event_notes;
create policy "notes insert participant"
  on public.event_notes for insert to authenticated
  with check (
    user_id = (select auth.uid())::text
    and public.can_read_event(event_id)
  );

drop policy if exists "notes update own or manager" on public.event_notes;
create policy "notes update own or manager"
  on public.event_notes for update to authenticated
  using (user_id = (select auth.uid())::text or public.can_manage_event(event_id));

drop policy if exists "notes delete own or manager" on public.event_notes;
create policy "notes delete own or manager"
  on public.event_notes for delete to authenticated
  using (user_id = (select auth.uid())::text or public.can_manage_event(event_id));

-- ---------------------------------------------------------------------------
--  circles
-- ---------------------------------------------------------------------------
drop policy if exists "circles select member" on public.circles;
create policy "circles select member"
  on public.circles for select to authenticated
  using (
    owner_id = (select auth.uid())::text
    or public.is_circle_member(id)
  );

drop policy if exists "circles insert owner" on public.circles;
create policy "circles insert owner"
  on public.circles for insert to authenticated
  with check (owner_id = (select auth.uid())::text);

drop policy if exists "circles update owner" on public.circles;
create policy "circles update owner"
  on public.circles for update to authenticated
  using (owner_id = (select auth.uid())::text)
  with check (owner_id = (select auth.uid())::text);

drop policy if exists "circles delete owner" on public.circles;
create policy "circles delete owner"
  on public.circles for delete to authenticated
  using (owner_id = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  circle_members
-- ---------------------------------------------------------------------------
drop policy if exists "members select same circle" on public.circle_members;
create policy "members select same circle"
  on public.circle_members for select to authenticated
  using (
    user_id = (select auth.uid())::text
    or public.is_circle_member(circle_id)
  );

-- You add yourself (accepting an invitation); the owner may add anyone (which
-- is what a couple-circle auto-share does).
drop policy if exists "members insert self or owner" on public.circle_members;
create policy "members insert self or owner"
  on public.circle_members for insert to authenticated
  with check (
    user_id = (select auth.uid())::text
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = (select auth.uid())::text
    )
  );

drop policy if exists "members delete self or owner" on public.circle_members;
create policy "members delete self or owner"
  on public.circle_members for delete to authenticated
  using (
    user_id = (select auth.uid())::text
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = (select auth.uid())::text
    )
  );

-- ---------------------------------------------------------------------------
--  invitations
-- ---------------------------------------------------------------------------
--  Readable by the sender and the person addressed, whether addressed by uid
--  (known account) or by email (not signed up yet).
drop policy if exists "invitations select sender or invitee" on public.invitations;
create policy "invitations select sender or invitee"
  on public.invitations for select to authenticated
  using (
    invited_by = (select auth.uid())::text
    or invitee_id = (select auth.uid())::text
    or lower(invitee_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

drop policy if exists "invitations insert manager" on public.invitations;
create policy "invitations insert manager"
  on public.invitations for insert to authenticated
  with check (
    invited_by = (select auth.uid())::text
    and public.can_manage_event(event_id)
  );

drop policy if exists "invitations update sender or invitee" on public.invitations;
create policy "invitations update sender or invitee"
  on public.invitations for update to authenticated
  using (
    invited_by = (select auth.uid())::text
    or invitee_id = (select auth.uid())::text
    or lower(invitee_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

drop policy if exists "invitations delete sender" on public.invitations;
create policy "invitations delete sender"
  on public.invitations for delete to authenticated
  using (invited_by = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  circle_invitations
-- ---------------------------------------------------------------------------
drop policy if exists "circle_invitations select sender or invitee" on public.circle_invitations;
create policy "circle_invitations select sender or invitee"
  on public.circle_invitations for select to authenticated
  using (
    invited_by = (select auth.uid())::text
    or invitee_id = (select auth.uid())::text
    or lower(invitee_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

drop policy if exists "circle_invitations insert owner" on public.circle_invitations;
create policy "circle_invitations insert owner"
  on public.circle_invitations for insert to authenticated
  with check (
    invited_by = (select auth.uid())::text
    and exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = (select auth.uid())::text
    )
  );

drop policy if exists "circle_invitations update sender or invitee" on public.circle_invitations;
create policy "circle_invitations update sender or invitee"
  on public.circle_invitations for update to authenticated
  using (
    invited_by = (select auth.uid())::text
    or invitee_id = (select auth.uid())::text
    or lower(invitee_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

drop policy if exists "circle_invitations delete sender" on public.circle_invitations;
create policy "circle_invitations delete sender"
  on public.circle_invitations for delete to authenticated
  using (invited_by = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  responses
-- ---------------------------------------------------------------------------
drop policy if exists "responses select own" on public.responses;
create policy "responses select own"
  on public.responses for select to authenticated
  using (recipient_id = (select auth.uid())::text);

-- Anyone may write one, but only as themselves: the responder email must be
-- their own, so an answer cannot be forged on someone else's behalf.
drop policy if exists "responses insert self" on public.responses;
create policy "responses insert self"
  on public.responses for insert to authenticated
  with check (
    responder_email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

drop policy if exists "responses update own" on public.responses;
create policy "responses update own"
  on public.responses for update to authenticated
  using (recipient_id = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  profiles
-- ---------------------------------------------------------------------------
drop policy if exists "profiles select authenticated" on public.profiles;
create policy "profiles select authenticated"
  on public.profiles for select to authenticated
  using (true);

drop policy if exists "profiles upsert own" on public.profiles;
create policy "profiles upsert own"
  on public.profiles for all to authenticated
  using (id = (select auth.uid())::text)
  with check (id = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  user_settings
-- ---------------------------------------------------------------------------
drop policy if exists "settings own" on public.user_settings;
create policy "settings own"
  on public.user_settings for all to authenticated
  using (user_id = (select auth.uid())::text)
  with check (user_id = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
--  notifications
-- ---------------------------------------------------------------------------
drop policy if exists "notifications select own" on public.notifications;
create policy "notifications select own"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid())::text);

-- Any signed-in user may notify someone else - that is how "your friend joined
-- your circle" is delivered.
drop policy if exists "notifications insert any" on public.notifications;
create policy "notifications insert any"
  on public.notifications for insert to authenticated
  with check (true);

drop policy if exists "notifications update own" on public.notifications;
create policy "notifications update own"
  on public.notifications for update to authenticated
  using (user_id = (select auth.uid())::text);

drop policy if exists "notifications delete own" on public.notifications;
create policy "notifications delete own"
  on public.notifications for delete to authenticated
  using (user_id = (select auth.uid())::text);


-- ============================================================================
--  PART 4 - REALTIME
-- ============================================================================
--  Adding a table to the publication is what makes `onPostgresChanges` fire.
--  RLS still applies to the broadcast.
-- ============================================================================
do $$
declare
  t text;
begin
  foreach t in array array['notifications', 'events', 'event_participants']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

alter table public.notifications replica identity full;
alter table public.events replica identity full;


-- ============================================================================
--  PART 5 - STORAGE - avatars bucket
-- ============================================================================
--  Public read (an avatar is shown to other people), writes restricted to the
--  owner's own folder: avatars/{firebase_uid}/{filename}
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

drop policy if exists "avatars write own folder" on storage.objects;
create policy "avatars write own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatars update own folder" on storage.objects;
create policy "avatars update own folder"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatars delete own folder" on storage.objects;
create policy "avatars delete own folder"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
