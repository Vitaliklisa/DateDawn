import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase connection settings.
///
/// Two sources, in priority order:
///
///  1. `.env` (loaded in `main()`), so a deploy can point at a different
///     Supabase project without touching code.
///  2. The constants below, which are the current project's values. They are
///     the fallback so the app still boots when `.env` is missing — a fresh
///     clone, a CI build, or a platform where asset loading failed.
///
/// Only the **publishable** key belongs here. It is designed to be public and
/// is protected by Row Level Security. The `sb_secret_...` key bypasses RLS
/// entirely and must never ship inside an app binary — it is for server-side
/// use only, and should be rotated if it has ever been shared.
const supabaseUrl = 'https://wktilnzinqkelpjcwsqv.supabase.co';
const supabasePublishableKey = 'sb_publishable_hommGM6hBArJ1GTGeqeQog_hrzpZrfQ';

/// The resolved project URL: `.env` first, constant second.
///
/// `dotenv.maybeGet` rather than `dotenv.env[...]` because reading `env`
/// before `load()` throws, and this getter is also called from tests that
/// never load a `.env` at all.
String get resolvedSupabaseUrl {
  final fromEnv = dotenv.maybeGet('SUPABASE_URL');
  return (fromEnv != null && fromEnv.isNotEmpty) ? fromEnv : supabaseUrl;
}

/// The resolved publishable key: `.env` first, constant second.
String get resolvedSupabasePublishableKey {
  final fromEnv = dotenv.maybeGet('SUPABASE_ANON_KEY');
  return (fromEnv != null && fromEnv.isNotEmpty)
      ? fromEnv
      : supabasePublishableKey;
}

/// Whether Supabase has enough configuration to attempt a connection.
bool get hasSupabaseConfig =>
    resolvedSupabaseUrl.isNotEmpty && resolvedSupabasePublishableKey.isNotEmpty;
