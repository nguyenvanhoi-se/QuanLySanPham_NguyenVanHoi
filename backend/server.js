const express = require('express');
const cors = require('cors');
const { MongoClient, ObjectId } = require('mongodb');
const { join } = require('node:path');
const { createHash, randomBytes, timingSafeEqual } = require('node:crypto');

process.loadEnvFile(join(__dirname, '.env'));
const { MONGODB_URI, ADMIN_EMAIL, ADMIN_PASSWORD } = process.env;
if (!MONGODB_URI || !ADMIN_EMAIL || !ADMIN_PASSWORD) {
  throw new Error('Điền MONGODB_URI, ADMIN_EMAIL và ADMIN_PASSWORD trong backend/.env.');
}

const app = express();
const client = new MongoClient(MONGODB_URI, {
  serverSelectionTimeoutMS: 5000,
});
const products = client.db().collection('products');
const sessions = new Map();

app.use(cors({ origin: 'http://localhost:8080' }));
app.use(express.json({ limit: '2mb' }));

function digest(value) {
  return createHash('sha256').update(value).digest();
}

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body ?? {};
  if (typeof email !== 'string' || typeof password !== 'string' ||
      email.trim().toLowerCase() !== ADMIN_EMAIL.toLowerCase() ||
      !timingSafeEqual(digest(password), digest(ADMIN_PASSWORD))) {
    return res.status(401).json({ message: 'Email hoặc mật khẩu chưa đúng.' });
  }
  const token = randomBytes(32).toString('hex');
  const now = Date.now();
  for (const [key, expires] of sessions) {
    if (expires <= now) sessions.delete(key);
  }
  sessions.set(token, now + 8 * 60 * 60 * 1000);
  res.set('Cache-Control', 'no-store').json({ token });
});

function requireAdmin(req, res, next) {
  const authorization = req.get('Authorization') ?? '';
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
  if ((sessions.get(token) ?? 0) <= Date.now()) {
    sessions.delete(token);
    return res.status(401).json({ message: 'Vui lòng đăng nhập quản trị.' });
  }
  res.locals.token = token;
  res.set('Cache-Control', 'no-store');
  next();
}

app.post('/api/auth/logout', requireAdmin, (req, res) => {
  sessions.delete(res.locals.token);
  res.json({ message: 'Đã đăng xuất.' });
});

app.use('/api/products', requireAdmin);

// Thêm và sửa dùng chung quy tắc kiểm tra 4 trường.
function validateProduct(req, res, next) {
  const { name, price, soluong, image } = req.body ?? {};

  if (typeof name !== 'string' || name.trim() === '') {
    return res.status(400).json({ message: 'Vui lòng nhập tên sản phẩm.' });
  }

  if (!Number.isSafeInteger(price) || price < 0) {
    return res.status(400).json({ message: 'Giá phải là số nguyên từ 0 trở lên.' });
  }

  if (!Number.isSafeInteger(soluong) || soluong < 0) {
    return res.status(400).json({ message: 'Số lượng phải là số nguyên từ 0 trở lên.' });
  }

  if (typeof image !== 'string' || image.trim() === '') {
    return res.status(400).json({ message: 'Vui lòng chọn ảnh sản phẩm.' });
  }

  res.locals.product = { name: name.trim(), price, soluong, image };
  next();
}

// Sửa và xóa đều cần tìm sản phẩm theo _id của MongoDB.
app.param('id', (req, res, next, id) => {
  if (!ObjectId.isValid(id)) {
    return res.status(400).json({ message: 'Mã sản phẩm không hợp lệ.' });
  }

  res.locals.productId = new ObjectId(id);
  next();
});

// 1. Xem danh sách hoặc tìm theo một phần tên sản phẩm.
app.get('/api/products', async (req, res) => {
  const search = req.query.search ?? '';

  if (typeof search !== 'string') {
    return res.status(400).json({ message: 'Từ khóa tìm kiếm không hợp lệ.' });
  }

  const keyword = search.trim();
  const filter = {};

  if (keyword) {
    // Tìm đúng ký tự người dùng nhập, kể cả dấu +, dấu chấm, dấu ngoặc.
    const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    filter.name = { $regex: escaped, $options: 'i' };
  }

  const productList = await products.find(filter).toArray();
  res.json(productList);
});

// 2. Thêm sản phẩm.
app.post('/api/products', validateProduct, async (req, res) => {
  const result = await products.insertOne(res.locals.product);
  res.status(201).json({
    message: 'Đã thêm sản phẩm.',
    id: result.insertedId.toString(),
  });
});

// 3. Sửa sản phẩm.
app.put('/api/products/:id', validateProduct, async (req, res) => {
  const result = await products.updateOne(
    { _id: res.locals.productId },
    { $set: res.locals.product }
  );

  if (result.matchedCount === 0) {
    return res.status(404).json({ message: 'Không tìm thấy sản phẩm.' });
  }

  res.json({ message: 'Đã cập nhật sản phẩm.', id: req.params.id });
});

// 4. Xóa sản phẩm.
app.delete('/api/products/:id', async (req, res) => {
  const result = await products.deleteOne({ _id: res.locals.productId });

  if (result.deletedCount === 0) {
    return res.status(404).json({ message: 'Không tìm thấy sản phẩm.' });
  }

  res.json({ message: 'Đã xóa sản phẩm.' });
});

async function startServer() {
  await client.connect();
  app.listen(3000, '127.0.0.1', () => {
    console.log('Danh sách sản phẩm: http://127.0.0.1:3000/api/products');
  });
}

startServer().catch((error) => {
  console.error('Không thể khởi động backend:', error.message);
  process.exitCode = 1;
});
