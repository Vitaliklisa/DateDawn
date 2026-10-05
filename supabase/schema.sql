-- ============================================================================
--  Date Dawn — Supabase schema for the Option B "two worlds" integration.
-- ============================================================================
--
--  HOW THIS FITS THE APP
--  ---------------------
--  Date Dawn keeps Firebase Auth + Firestore as the source of truth for
--  countdowns, circles and invitations. Supabase runs ALONGSIDE it and owns
--  exactly two things:
--
--    1. `user_settings`   — appearance, synced across a user's devices.
--    2. `notifications`   — an in-app notification inbox, pushed live over
--                           Supabase Realtime.
--
--  Plus Supabase Storage for avatar uploads.
--
--  The single hard problem in a two-backend setup is identity: Firebase issues
--  the user id, Supabase issues its own `auth.uid()`. Every table below is
--  keyed on the FIREBASE uid (a `text` column), not on Supabase's `uuid`, so
--  the two systems agree on who a row belongs to without a mapping table.
--
--  SECURITY — READ THIS
--  --------------------
--  Because the app authenticates with Firebase, Postgres cannot verify the
--  caller itself: there is no Supabase JWT on the request. A "the client sends
--  its own uid" policy is therefore NOT a real access control — any user could
--  send someone else's uid.
--
--  So this file is split into two clearly-marked halves:
--
--    PART 1 (dev / demo): permissive policies that make the app work today.
--    PART 2 (production):  the locked-down policies, which require the
--                          Firebase->Supabase token exchange described in
--                          docs/SUPABASE_INTEGRATION.md. Flip to PART 2 when
--                          that is in place.
--
--  Run PART 1 to start. Read PART 2 before you put real user data in here.
-- ============================================================================


-- ============================================================================
--  PART 1 — SCHEMA
-- ============================================================================

-- ---------------------------------------------------------------------------
--  profiles
-- ---------------------------------------------------------------------------
--  The public half of an account: a display name and an avatar. Mirrors the
--  Firebase `users` collection so a Supabase-only feature (avatar upload) can
--  resolve a person without reading Firestore.
--
--  `id` is the Firebase uid, kept as text for that reason.
create table if not exists public.profiles (
  id          text primary key,
  username    text,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is
  'Public profile per account. id = Firebase uid.';


-- ---------------------------------------------------------------------------
--  user_settings
-- ---------------------------------------------------------------------------
--  Appearance, one row per user. This is the table the Settings screen writes
--  to on every theme change, so the change follows the user to their other
--  devices instead of being stuck on one phone.
--
--  `theme_mode` is constrained rather than free text: the client maps the
--  string straight onto Flutter's ThemeMode, so an unexpected value would
--  crash the parse. The check makes that impossible at the source.
create table if not exists public.user_settings (
  user_id     text primary key,
  theme_mode  text not null default 'system'
              check (theme_mode in ('light', 'dark', 'system')),
  updated_at  timestamptz not null default now()
);

comment on table public.user_settings is
  'Per-user appearance. theme_mode is one of light | dark | system.';


-- ---------------------------------------------------------------------------
--  circles
-- ---------------------------------------------------------------------------
--  A standing group you count down with. Mirrors the Firestore `circles`
--  collection; `owner_id` is a Firebase uid.
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
--  circle_members
-- ---------------------------------------------------------------------------
--  Who is in which circle. `user_id` is a Firebase uid; the row's own `id` is
--  a real uuid because it is Supabase-only.
--
--  `role` distinguishes the owner from everyone else, which is what the
--  "only the owner can invite" rule in the app relies on.
create table if not exists public.circle_members (
  id         uuid primary key default gen_random_uuid(),
  circle_id  uuid not null references public.circles (id) on delete cascade,
  user_id    text not null,
  role       text not null default 'member'
             check (role in ('owner', 'admin', 'member')),
  joined_at  timestamptz not null default now(),
  -- A person joins a given circle once. Makes "join" idempotent, which matters
  -- because accepting an invitation can be retried after a dropped connection.
  unique (circle_id, user_id)
);

create index if not exists circle_members_user_idx
  on public.circle_members (user_id);
create index if not exists circle_members_circle_idx
  on public.circle_members (circle_id);


-- ---------------------------------------------------------------------------
--  invitations
-- ---------------------------------------------------------------------------
--  An invite into a circle. `sender_id` and `receiver_id` are Firebase uids.
--
--  `receiver_id` is nullable on purpose: the app invites by EMAIL, and the
--  person may not have signed in yet. Until they do, the invite is addressed
--  to `receiver_email` and is claimed on first sign-in.
create table if not exists public.invitations (
  id              uuid primary key default gen_random_uuid(),
  sender_id       text not null,
  receiver_id     text,
  receiver_email  text,
  circle_id       uuid not null references public.circles (id) on delete cascade,
  status          text not null default 'pending'
                  check (status in ('pending', 'accepted', 'declined')),
  created_at      timestamptz not null default now(),
  -- Answering twice should not be possible; the app flips pending -> answered
  -- exactly once.
  responded_at    timestamptz
);

create index if not exists invitations_receiver_idx
  on public.invitations (receiver_id);
create index if not exists invitations_email_idx
  on public.invitations (lower(receiver_email));
create index if not exists invitations_circle_idx
  on public.invitations (circle_id);


-- ---------------------------------------------------------------------------
--  notifications
-- ---------------------------------------------------------------------------
--  The in-app inbox, streamed live to the client over Supabase Realtime.
--
--  `user_id` is the Firebase uid of the recipient. The `type` column lets the
--  UI pick an icon and, later, a destination route without parsing the body
--  text.
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

-- The inbox query is always "my notifications, newest first", so index for it.
create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);


-- ---------------------------------------------------------------------------
--  updated_at maintenance
-- ---------------------------------------------------------------------------
--  `updated_at` is set by the database rather than trusted from the client, so
--  a wrong device clock cannot corrupt the ordering.
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


-- ---------------------------------------------------------------------------
--  New-user bootstrap
-- ---------------------------------------------------------------------------
--  When someone signs up through SUPABASE auth, give them a profile and a
--  default settings row so the app never has to handle "no row yet".
--
--  Note: with Firebase Auth as the identity provider this trigger does not
--  fire — the app upserts both rows itself on first sign-in. It is here so the
--  schema is correct if you later move auth to Supabase.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id::text,
    coalesce(new.raw_user_meta_data ->> 'full_name',
             new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.user_settings (user_id, theme_mode)
  values (new.id::text, 'system')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ---------------------------------------------------------------------------
--  Helper: is the caller a member of this circle?
-- ---------------------------------------------------------------------------
--  Written as a `security definer` function so the membership check can read
--  `circle_members` without itself being subject to that table's RLS. Without
--  this, a policy on `circles` that queries `circle_members` would recurse
--  into the policy on `circle_members`, and Postgres would reject the query.
create or replace function public.is_circle_member(p_circle_id uuid, p_user_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.circle_members m
    where m.circle_id = p_circle_id
      and m.user_id = p_user_id
  );
$$;


-- ---------------------------------------------------------------------------
--  Enable RLS everywhere
-- ---------------------------------------------------------------------------
--  Nothing is readable without a policy. A table with RLS on and no policy is
--  closed, which is the correct default if a policy below is ever dropped.
alter table public.profiles       enable row level security;
alter table public.user_settings  enable row level security;
alter table public.circles        enable row level security;
alter table public.circle_members enable row level security;
alter table public.invitations    enable row level security;
alter table public.notifications  enable row level security;


-- ============================================================================
--  PART 2 — ROW LEVEL SECURITY
-- ============================================================================
--
--  !!! READ THE SECURITY NOTE AT THE TOP OF THIS FILE !!!
--
--  These policies are written against `auth.uid()`, which is the Supabase
--  identity. In the Option B setup the app signs in with FIREBASE, so
--  `auth.uid()` is NULL on every request and these policies would deny
--  everything.
--
--  They are provided so the schema is production-ready: once the
--  Firebase -> Supabase token exchange is wired (see the integration doc),
--  Supabase will issue a JWT whose `sub` claim is the Firebase uid, `auth.uid()`
--  will resolve, and these policies become live and correct.
--
--  Until then, PART 3 below is what makes the app work. Keep PART 3 while you
--  are developing; drop it before production.
-- ============================================================================

-- ---------- profiles ----------
-- Readable by any signed-in user: an inviter needs to resolve a uid to a name
-- and avatar. Only the owner may write.
drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated"
  on public.profiles for select
  to authenticated
  using (true);

drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid()::text = id);

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own"
  on public.profiles for update
  to authenticated
  using (auth.uid()::text = id)
  with check (auth.uid()::text = id);


-- ---------- user_settings ----------
-- Strictly private: your appearance is nobody else's business.
drop policy if exists "settings select own" on public.user_settings;
create policy "settings select own"
  on public.user_settings for select
  to authenticated
  using (auth.uid()::text = user_id);

drop policy if exists "settings insert own" on public.user_settings;
create policy "settings insert own"
  on public.user_settings for insert
  to authenticated
  with check (auth.uid()::text = user_id);

drop policy if exists "settings update own" on public.user_settings;
create policy "settings update own"
  on public.user_settings for update
  to authenticated
  using (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);


-- ---------- circles ----------
-- You see a circle you own or belong to. You may create only a circle you own.
drop policy if exists "circles select member" on public.circles;
create policy "circles select member"
  on public.circles for select
  to authenticated
  using (
    owner_id = auth.uid()::text
    or public.is_circle_member(id, auth.uid()::text)
  );

drop policy if exists "circles insert owner" on public.circles;
create policy "circles insert owner"
  on public.circles for insert
  to authenticated
  with check (owner_id = auth.uid()::text);

-- Only the owner may rename or re-describe the circle.
drop policy if exists "circles update owner" on public.circles;
create policy "circles update owner"
  on public.circles for update
  to authenticated
  using (owner_id = auth.uid()::text)
  with check (owner_id = auth.uid()::text);

drop policy if exists "circles delete owner" on public.circles;
create policy "circles delete owner"
  on public.circles for delete
  to authenticated
  using (owner_id = auth.uid()::text);


-- ---------- circle_members ----------
-- Visible to fellow members. You may add yourself (accepting an invitation) or
-- be added by the circle's owner; you may remove yourself (leaving).
drop policy if exists "members select same circle" on public.circle_members;
create policy "members select same circle"
  on public.circle_members for select
  to authenticated
  using (public.is_circle_member(circle_id, auth.uid()::text));

drop policy if exists "members insert self or owner" on public.circle_members;
create policy "members insert self or owner"
  on public.circle_members for insert
  to authenticated
  with check (
    user_id = auth.uid()::text
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = auth.uid()::text
    )
  );

drop policy if exists "members delete self or owner" on public.circle_members;
create policy "members delete self or owner"
  on public.circle_members for delete
  to authenticated
  using (
    user_id = auth.uid()::text
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = auth.uid()::text
    )
  );


-- ---------- invitations ----------
-- Readable by the sender and the person invited (by uid once known, or by
-- email before they have an account). Only the sender creates one, and only
-- the receiver answers it.
drop policy if exists "invitations select sender or receiver" on public.invitations;
create policy "invitations select sender or receiver"
  on public.invitations for select
  to authenticated
  using (
    sender_id = auth.uid()::text
    or receiver_id = auth.uid()::text
    or lower(receiver_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

drop policy if exists "invitations insert sender" on public.invitations;
create policy "invitations insert sender"
  on public.invitations for insert
  to authenticated
  with check (sender_id = auth.uid()::text);

-- The receiver may accept or decline; the sender may cancel.
drop policy if exists "invitations update sender or receiver" on public.invitations;
create policy "invitations update sender or receiver"
  on public.invitations for update
  to authenticated
  using (
    sender_id = auth.uid()::text
    or receiver_id = auth.uid()::text
    or lower(receiver_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
  with check (
    sender_id = auth.uid()::text
    or receiver_id = auth.uid()::text
    or lower(receiver_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );


-- ---------- notifications ----------
-- Strictly private: you read, update and delete only your own.
drop policy if exists "notifications select own" on public.notifications;
create policy "notifications select own"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid()::text);

-- Any signed-in user may create a notification for someone else — that is how
-- "your friend joined your circle" is delivered. Forging spam is bounded by
-- the rate limit below rather than by a policy.
drop policy if exists "notifications insert any" on public.notifications;
create policy "notifications insert any"
  on public.notifications for insert
  to authenticated
  with check (true);

drop policy if exists "notifications update own" on public.notifications;
create policy "notifications update own"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid()::text)
  with check (user_id = auth.uid()::text);

drop policy if exists "notifications delete own" on public.notifications;
create policy "notifications delete own"
  on public.notifications for delete
  to authenticated
  using (user_id = auth.uid()::text);


-- ============================================================================
--  PART 3 — DEV / DEMO POLICIES  (remove before production)
-- ============================================================================
--
--  The app authenticates with Firebase, so Supabase sees an ANONYMOUS request
--  and `auth.uid()` is NULL — PART 2 above would deny every read and write.
--
--  These policies grant the `anon` role access scoped by an EXPLICIT uid the
--  client passes, which is enough to develop and demo against, and is honest
--  about what it is: a convenience, not a security boundary. A determined
--  user can read or write another user's rows while these are active.
--
--  Therefore:
--    * Do not store anything sensitive here in this mode.
--    * Remove this whole section (or swap to PART 2) before production.
--
--  The client tags every request with `x-user-id`; see
--  `lib/services/supabase_service.dart`.
-- ============================================================================

-- The header is read through a helper so the intent is visible in each policy
-- and there is one place to change the mechanism.
create or replace function public.request_user_id()
returns text
language sql
stable
as $$
  select nullif(
    current_setting('request.headers', true)::json ->> 'x-user-id',
    ''
  );
$$;

-- ---------- profiles ----------
drop policy if exists "dev profiles select" on public.profiles;
create policy "dev profiles select"
  on public.profiles for select
  to anon, authenticated
  using (true);

drop policy if exists "dev profiles upsert own" on public.profiles;
create policy "dev profiles upsert own"
  on public.profiles for all
  to anon, authenticated
  using (id = public.request_user_id())
  with check (id = public.request_user_id());

-- ---------- user_settings ----------
drop policy if exists "dev settings own" on public.user_settings;
create policy "dev settings own"
  on public.user_settings for all
  to anon, authenticated
  using (user_id = public.request_user_id())
  with check (user_id = public.request_user_id());

-- ---------- circles ----------
drop policy if exists "dev circles member" on public.circles;
create policy "dev circles member"
  on public.circles for select
  to anon, authenticated
  using (
    owner_id = public.request_user_id()
    or public.is_circle_member(id, public.request_user_id())
  );

drop policy if exists "dev circles insert" on public.circles;
create policy "dev circles insert"
  on public.circles for insert
  to anon, authenticated
  with check (owner_id = public.request_user_id());

drop policy if exists "dev circles update" on public.circles;
create policy "dev circles update"
  on public.circles for update
  to anon, authenticated
  using (owner_id = public.request_user_id())
  with check (owner_id = public.request_user_id());

drop policy if exists "dev circles delete" on public.circles;
create policy "dev circles delete"
  on public.circles for delete
  to anon, authenticated
  using (owner_id = public.request_user_id());

-- ---------- circle_members ----------
drop policy if exists "dev members select" on public.circle_members;
create policy "dev members select"
  on public.circle_members for select
  to anon, authenticated
  using (public.is_circle_member(circle_id, public.request_user_id()));

drop policy if exists "dev members insert" on public.circle_members;
create policy "dev members insert"
  on public.circle_members for insert
  to anon, authenticated
  with check (
    user_id = public.request_user_id()
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = public.request_user_id()
    )
  );

drop policy if exists "dev members delete" on public.circle_members;
create policy "dev members delete"
  on public.circle_members for delete
  to anon, authenticated
  using (
    user_id = public.request_user_id()
    or exists (
      select 1 from public.circles c
      where c.id = circle_id and c.owner_id = public.request_user_id()
    )
  );

-- ---------- invitations ----------
drop policy if exists "dev invitations select" on public.invitations;
create policy "dev invitations select"
  on public.invitations for select
  to anon, authenticated
  using (
    sender_id = public.request_user_id()
    or receiver_id = public.request_user_id()
  );

drop policy if exists "dev invitations insert" on public.invitations;
create policy "dev invitations insert"
  on public.invitations for insert
  to anon, authenticated
  with check (sender_id = public.request_user_id());

drop policy if exists "dev invitations update" on public.invitations;
create policy "dev invitations update"
  on public.invitations for update
  to anon, authenticated
  using (
    sender_id = public.request_user_id()
    or receiver_id = public.request_user_id()
  )
  with check (
    sender_id = public.request_user_id()
    or receiver_id = public.request_user_id()
  );

-- ---------- notifications ----------
drop policy if exists "dev notifications select" on public.notifications;
create policy "dev notifications select"
  on public.notifications for select
  to anon, authenticated
  using (user_id = public.request_user_id());

drop policy if exists "dev notifications insert" on public.notifications;
create policy "dev notifications insert"
  on public.notifications for insert
  to anon, authenticated
  with check (true);

drop policy if exists "dev notifications update" on public.notifications;
create policy "dev notifications update"
  on public.notifications for update
  to anon, authenticated
  using (user_id = public.request_user_id())
  with check (user_id = public.request_user_id());

drop policy if exists "dev notifications delete" on public.notifications;
create policy "dev notifications delete"
  on public.notifications for delete
  to anon, authenticated
  using (user_id = public.request_user_id());


-- ============================================================================
--  REALTIME
-- ============================================================================
--  Realtime must be told which tables to broadcast. Adding a table to the
--  publication is what makes `onPostgresChanges` fire for it.
--
--  `notifications` is the one the app subscribes to. RLS still applies to the
--  broadcast: with PART 3 active, filtering happens client-side by user_id
--  (see the service), and with PART 2 active Postgres filters for you.
-- ============================================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- Full row data on update/delete, so a client sees WHICH row changed.
alter table public.notifications replica identity full;


-- ============================================================================
--  STORAGE — avatars bucket
-- ============================================================================
--  Supabase Storage holds profile pictures. Public read (an avatar is shown to
--  other people), but writes are restricted to the owner's own folder.
--
--  Path convention: avatars/{firebase_uid}/{filename}
--  The first path segment is the uid, which is what the policies match on.
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

-- Dev-mode write policy: the client sends x-user-id and may only write inside
-- its own folder. Swap for the auth.uid()-based version below in production.
drop policy if exists "avatars write own folder (dev)" on storage.objects;
create policy "avatars write own folder (dev)"
  on storage.objects for insert
  to anon, authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = public.request_user_id()
  );

drop policy if exists "avatars update own folder (dev)" on storage.objects;
create policy "avatars update own folder (dev)"
  on storage.objects for update
  to anon, authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = public.request_user_id()
  );

drop policy if exists "avatars delete own folder (dev)" on storage.objects;
create policy "avatars delete own folder (dev)"
  on storage.objects for delete
  to anon, authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = public.request_user_id()
  );

-- Production versions, for when Supabase auth is live:
--
--   create policy "avatars write own folder"
--     on storage.objects for insert to authenticated
--     with check (
--       bucket_id = 'avatars'
--       and (storage.foldername(name))[1] = auth.uid()::text
--     );
