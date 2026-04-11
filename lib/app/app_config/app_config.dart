/// App-wide configuration constants
/// Replace with your actual Supabase project credentials
class AppConfig {
  // ─── Supabase ───────────────────────────────────────
  // Get these from: Supabase Dashboard → Settings → API
  static const supabaseUrl     = 'https://mrduibsziktaxliejhoz.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_PXH9hpp5awilEgv_28dfOw_M8ieMlxS';

  // ─── App ────────────────────────────────────────────
  static const appName    = 'SaveSmart';
  static const appVersion = '1.0.0';

  // ─── Admin ──────────────────────────────────────────
  // The UUID of the admin user (set after first run)
  static const adminId = 'YOUR_ADMIN_UUID_HERE';
}
