# Cofindinleads Web Companion

This folder contains a minimal React + TypeScript + Tailwind scaffold intended to be a lightweight web companion for the mobile app. It is configured to reuse the existing Supabase authentication and will include pages for login, profile browsing and an admin dashboard.

Quick start:

1. cd web
2. npm install
3. Create a `.env.local` in `web/` with the following keys:

VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key

4. Copy app assets into `web/public/assets` (if you have the Flutter `assets/` folder at repo root run `../scripts/copy_assets.sh` from `web/`)
5. npm run dev

Notes:
- This project reuses Supabase for auth and data. Ensure your Supabase project has CORS and redirect URLs set for the web origin.
- OAuth providers (Google/Apple) must be configured in Supabase with the web redirect URL.
- The `scripts/copy_assets.sh` will copy assets from the repo root `assets/` directory into `web/public/assets` if present.



