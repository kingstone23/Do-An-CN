/**
 * Harvest & Hearth API — MongoDB + Clerk session JWT verification.
 *
 * Env: MONGODB_URI, CLERK_SECRET_KEY, PORT (optional, default 8787)
 * Middleware: compression (gzip), CORS, trust proxy (Render / reverse proxy).
 */
import compression from 'compression';
import cors from 'cors';
import express from 'express';
import { verifyToken } from '@clerk/backend';
import { MongoClient } from 'mongodb';

const PORT = Number(process.env.PORT) || 8787;
const MONGODB_URI = process.env.MONGODB_URI || '';
const CLERK_SECRET_KEY = process.env.CLERK_SECRET_KEY || '';

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '2mb' }));

let db;
let client;

async function connectMongo() {
  if (!MONGODB_URI) {
    console.error('Missing MONGODB_URI');
    process.exit(1);
  }
  client = new MongoClient(MONGODB_URI);
  await client.connect();
  db = client.db();
  console.log('MongoDB connected');
}

function profiles() {
  return db.collection('profiles');
}
function foodItems() {
  return db.collection('food_items');
}
function savedRecipes() {
  return db.collection('saved_recipes');
}

async function clerkAuth(req, res, next) {
  if (!CLERK_SECRET_KEY) {
    return res.status(500).json({ error: 'Server missing CLERK_SECRET_KEY' });
  }
  const h = req.headers.authorization;
  if (!h?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Bearer token' });
  }
  const token = h.slice(7);
  try {
    const payload = await verifyToken(token, { secretKey: CLERK_SECRET_KEY });
    req.userId = payload.sub;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

// ── Profile ────────────────────────────────────────────────────────────────
app.get('/api/v1/profile', clerkAuth, async (req, res) => {
  const uid = req.userId;
  let doc = await profiles().findOne({ _id: uid });
  if (!doc) {
    doc = {
      _id: uid,
      email: null,
      name: null,
      language: 'VIE',
      is_dark: false,
      updated_at: new Date(),
    };
    await profiles().insertOne(doc);
  }
  res.json({
    id: doc._id,
    email: doc.email,
    name: doc.name,
    language: doc.language,
    is_dark: doc.is_dark,
  });
});

app.put('/api/v1/profile', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const body = req.body || {};
  const patch = {
    updated_at: new Date(),
  };
  if ('email' in body) patch.email = body.email;
  if ('name' in body) patch.name = body.name;
  if ('language' in body) patch.language = body.language;
  if ('is_dark' in body) patch.is_dark = Boolean(body.is_dark);

  await profiles().updateOne(
    { _id: uid },
    { $set: patch },
    { upsert: true },
  );
  const doc = await profiles().findOne({ _id: uid });
  res.json({
    id: doc._id,
    email: doc.email,
    name: doc.name,
    language: doc.language,
    is_dark: doc.is_dark,
  });
});

// ── Food items ─────────────────────────────────────────────────────────────
app.get('/api/v1/food-items', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = await foodItems()
    .find({ user_id: uid })
    .sort({ created_at: -1 })
    .toArray();
  res.json(
    rows.map((r) => ({
      id: r.id,
      user_id: r.user_id,
      name: r.name,
      category: r.category,
      storage: r.storage,
      quantity: r.quantity,
      unit: r.unit,
      added_date: r.added_date instanceof Date ? r.added_date.toISOString() : r.added_date,
      expiry_date:
        r.expiry_date == null
          ? null
          : r.expiry_date instanceof Date
            ? r.expiry_date.toISOString()
            : r.expiry_date,
      warning_days: r.warning_days,
    })),
  );
});

app.post('/api/v1/food-items', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = Array.isArray(req.body) ? req.body : [req.body];
  const now = new Date();
  const docs = rows.map((item) => ({
    id: item.id,
    user_id: uid,
    name: item.name,
    category: item.category,
    storage: item.storage,
    quantity: item.quantity,
    unit: item.unit,
    added_date: item.added_date,
    expiry_date: item.expiry_date ?? null,
    warning_days: item.warning_days ?? null,
    created_at: now,
  }));
  if (docs.some((d) => !d.id)) {
    return res.status(400).json({ error: 'Each item needs id' });
  }
  await foodItems().insertMany(docs);
  res.status(201).json({ ok: true });
});

app.patch('/api/v1/food-items/:id', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  const body = req.body || {};
  const r = await foodItems().findOne({ id, user_id: uid });
  if (!r) {
    return res.status(404).json({ error: 'Not found' });
  }
  const set = {};
  if ('name' in body) set.name = body.name;
  if ('category' in body) set.category = body.category;
  if ('storage' in body) set.storage = body.storage;
  if ('quantity' in body) set.quantity = body.quantity;
  if ('unit' in body) set.unit = body.unit;
  if ('added_date' in body) set.added_date = body.added_date;
  if ('expiry_date' in body) set.expiry_date = body.expiry_date;
  if ('warning_days' in body) set.warning_days = body.warning_days;
  await foodItems().updateOne({ id, user_id: uid }, { $set: set });
  res.json({ ok: true });
});

app.delete('/api/v1/food-items/:id', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  await foodItems().deleteOne({ id, user_id: uid });
  res.json({ ok: true });
});

// ── Saved recipes ────────────────────────────────────────────────────────────
app.get('/api/v1/saved-recipes', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = await savedRecipes()
    .find({ user_id: uid })
    .sort({ created_at: -1 })
    .toArray();
  res.json(
    rows.map((r) => ({
      user_id: r.user_id,
      original_id: r.original_id,
      recipe_data: r.recipe_data,
    })),
  );
});

app.post('/api/v1/saved-recipes', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { original_id, recipe_data } = req.body || {};
  if (!original_id || !recipe_data) {
    return res.status(400).json({ error: 'original_id and recipe_data required' });
  }
  await savedRecipes().updateOne(
    { user_id: uid, original_id: String(original_id) },
    {
      $set: {
        user_id: uid,
        original_id: String(original_id),
        recipe_data,
        created_at: new Date(),
      },
    },
    { upsert: true },
  );
  res.status(201).json({ ok: true });
});

app.delete('/api/v1/saved-recipes/:originalId', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { originalId } = req.params;
  await savedRecipes().deleteOne({
    user_id: uid,
    original_id: originalId,
  });
  res.json({ ok: true });
});

async function main() {
  await connectMongo();
  await foodItems().createIndex({ user_id: 1 });
  await foodItems().createIndex({ id: 1, user_id: 1 }, { unique: true });
  await savedRecipes().createIndex({ user_id: 1 });
  await savedRecipes().createIndex(
    { user_id: 1, original_id: 1 },
    { unique: true },
  );

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`API listening on 0.0.0.0:${PORT}`);
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
