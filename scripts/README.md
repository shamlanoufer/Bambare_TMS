# Firestore seed (tours)

This folder uploads the **same tour list** that used to live in the app into the **`tours`** collection. Bookings still go from the app to **`bookings`** when users book (no extra step).

## What you need

1. **Service account key** (not your Google login — a JSON key for server/admin):
   - Firebase Console → Project settings (gear) → **Service accounts**
   - **Generate new private key** → save the JSON file somewhere safe (do not commit it to git).

2. **Node.js** installed (LTS).

## One-time setup

```powershell
cd scripts
npm install
```

## If you see `NOT_FOUND` (code 5)

In [Firebase Console](https://console.firebase.google.com/) open project **bambare-tms-e1cc5** → **Build** → **Firestore Database** → **Create database** (choose location, enable). Wait until it finishes, then run `seed_tours.mjs` again.

## Run seed (Windows PowerShell)

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\your-service-account.json"
node seed_tours.mjs
```

Replace the path with your actual JSON file path.

## Run seed (cmd.exe)

```cmd
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\your-service-account.json
cd scripts
node seed_tours.mjs
```

After this, open Firestore in the console: you should see **`tours`** with 9 documents. The app will load them automatically.

### Admin fields (same as Console)

| Field | Purpose |
|--------|---------|
| `title`, `image_url`, `rating`, `category`, `price`, `currency`, `location` | Tour card + detail |
| `sort_order` | **Discover** list order (1 = first) |
| `published` | `false` = hidden in app |
| `featured` | `true` = shown under home **Popular Tours** |
| `featured_rank` | Order on home when featured (`1`, `2`, `3`…) |

Manual entry: use **`tours_firestore_reference.json`** in this folder — each `documents[]` item: create doc with that **id**, paste the other fields.

### Service account JSON location

You can keep the downloaded key **anywhere** (e.g. `C:\Secrets\my-project-firebase-adminsdk.json`). Point `GOOGLE_APPLICATION_CREDENTIALS` to that path. **Do not** commit the key to git; if you put `serviceAccountKey.json` under `scripts/`, keep it only local.

## Security

- Never share the service account JSON or commit it to GitHub.
- Firebase CLI “logged in” is different from this key; the script **only** needs the JSON path for one-off seeding.
