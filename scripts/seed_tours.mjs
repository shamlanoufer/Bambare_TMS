/**
 * Admin-style seed for Firestore `tours` (matches app + your design screenshots).
 * Home “Popular Tours”: featured items only. Discover: all published, by sort_order.
 *
 * Run: npm install  then  GOOGLE_APPLICATION_CREDENTIALS=... node seed_tours.mjs
 */

import { readFileSync } from 'fs';

import admin from 'firebase-admin';

const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credPath) {
  console.error(
    'Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON path.',
  );
  process.exit(1);
}

const serviceAccount = JSON.parse(readFileSync(credPath, 'utf8'));

const projectId = serviceAccount.project_id;
if (!projectId) {
  console.error('Invalid service account: missing project_id');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId,
});

console.log(`Using Firebase project: ${projectId}`);

const db = admin.firestore();

/** Discover list order = sort_order. Home popular = featured + featured_rank */
const tours = [
  {
    id: 'sigiriya-rock-fortress',
    title: 'Sigiriya Rock Fortress',
    image_url: 'images/Sigiriya Rock Fortress.png',
    rating: 4.9,
    category: 'CULTURAL',
    price: 8500,
    currency: 'LKR',
    location: 'Dambulla',
    sort_order: 1,
    published: true,
    featured: true,
    featured_rank: 1,
  },
  {
    id: 'yala-safari-experience',
    title: 'Yala Safari Experience',
    image_url: 'images/Yala Safari Experience.png',
    rating: 4.8,
    category: 'WILDLIFE',
    price: 18500,
    currency: 'LKR',
    location: 'Yala',
    sort_order: 2,
    published: true,
    featured: false,
    featured_rank: 0,
  },
  {
    id: 'mirissa-whale-watching',
    title: 'Mirissa Whale Watching',
    image_url: 'images/Mirissa Whale Watching.png',
    rating: 4.7,
    category: 'OCEAN',
    price: 20500,
    currency: 'LKR',
    location: 'Mirissa',
    sort_order: 3,
    published: true,
    featured: false,
    featured_rank: 0,
  },
  {
    id: 'ella-train-experience',
    title: 'Ella Train Experience',
    image_url: 'images/Ella Train Experience.png',
    rating: 4.9,
    category: 'SCENIC',
    price: 25000,
    currency: 'LKR',
    location: 'Ella',
    sort_order: 4,
    published: true,
    featured: false,
    featured_rank: 0,
  },
  {
    id: 'marble-beach',
    title: 'Marble Beach',
    image_url: 'images/Marble Beach.png',
    rating: 4.6,
    category: 'BEACH',
    price: 30500,
    currency: 'LKR',
    location: 'Trincomalee',
    sort_order: 5,
    published: true,
    featured: false,
    featured_rank: 0,
  },
  {
    id: 'piduruthalagala-hiking',
    title: 'Piduruthalagala Hiking',
    image_url: 'images/Piduruthalagala Hiking.png',
    rating: 4.5,
    category: 'MOUNTAIN',
    price: 8500,
    currency: 'LKR',
    location: 'Piduruthalagala',
    sort_order: 6,
    published: true,
    featured: false,
    featured_rank: 0,
  },
  {
    id: 'kandy-heritage-city',
    title: 'Kandy Heritage City',
    image_url: 'images/Kandy Heritage City (2).png',
    rating: 4.9,
    category: 'CULTURAL',
    price: 8500,
    currency: 'LKR',
    location: 'Kandy',
    sort_order: 7,
    published: true,
    featured: true,
    featured_rank: 2,
  },
  {
    id: 'udunuwara-village',
    title: 'Udunuwara Village',
    image_url: 'images/Udunuwara Village (2).png',
    rating: 4.9,
    category: 'CULTURAL',
    price: 8500,
    currency: 'LKR',
    location: 'Udunuwara',
    sort_order: 8,
    published: true,
    featured: true,
    featured_rank: 3,
  },
  {
    id: 'sri-lankan-food',
    title: 'Sri Lankan Food',
    image_url: 'images/Sri Lankan Food.png',
    rating: 4.9,
    category: 'FOOD',
    price: 8500,
    currency: 'LKR',
    location: 'Kandy',
    sort_order: 9,
    published: true,
    featured: false,
    featured_rank: 0,
  },
];

async function main() {
  const batch = db.batch();
  for (const t of tours) {
    const { id, ...fields } = t;
    batch.set(db.collection('tours').doc(id), fields, { merge: true });
  }
  await batch.commit();
  console.log(`Done: upserted ${tours.length} documents in "tours".`);
}

main().catch((err) => {
  console.error(err);
  if (err?.code === 5) {
    console.error(
      '\nFirestore returned NOT_FOUND. In Firebase Console: open project → Firestore Database → Create database (start once). Then run this script again.',
    );
  }
  process.exit(1);
});
