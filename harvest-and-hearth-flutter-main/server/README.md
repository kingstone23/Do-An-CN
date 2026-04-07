# Harvest & Hearth API

REST API kết nối **MongoDB Atlas (cloud)** qua biến **`MONGODB_URI`** và xác thực **Clerk** (JWT session từ app Flutter).

## Cần có

- Node.js **18+**
- **MongoDB Atlas**: cluster cloud, connection string `mongodb+srv://...`
- Clerk **Secret key** (Dashboard → API Keys) — chỉ dùng trên server, không đưa vào app

## Cấu hình Atlas + `MONGODB_URI`

1. [MongoDB Atlas](https://cloud.mongodb.com) → project/cluster của bạn.
2. **Database** → **Connect** → **Drivers** → copy URI, thay `<password>` bằng user database.
3. **Network Access** → **Add IP Address** (dev có thể tạm `0.0.0.0/0`; production nên hạn chế IP máy chạy API).
4. Tạo file **`server/.env`** từ `.env.example`:

```env
MONGODB_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/harvest_hearth?retryWrites=true&w=majority
CLERK_SECRET_KEY=sk_test_...
PORT=8787
```

`MONGODB_URI` **không** đặt trong `.env` của app Flutter — chỉ API Node đọc chuỗi này.

### URI sai → `MongoParseError` khi deploy

- **Một** ký tự `@` giữa `password` và hostname: `...PASSWORD@cluster0...` — không được `@@`. Nếu mật khẩu có ký tự đặc biệt (`@`, `#`, `:`, …), [URL-encode](https://www.mongodb.com/docs/manual/reference/connection-string/) phần password (ví dụ `@` → `%40`).
- Chuỗi query: sau `?` tham số đầu tiên, các tham số sau dùng **`&`**, không dùng `?` lần hai. Sai: `?appName=x?retryWrites=...` — Đúng: `?appName=x&retryWrites=true&w=majority`.
- Trên **Render**, sửa biến `MONGODB_URI` rồi **Manual Deploy** lại. Nếu URI từng lộ trong log, nên **đổi mật khẩu** user database trên Atlas.

## Chạy

```bash
cd server
cp .env.example .env   # điền MONGODB_URI (Atlas) + CLERK_SECRET_KEY
npm install
npm start
```

Kiểm tra: `GET http://localhost:8787/health` → `{ "ok": true }`.

## Endpoints (tất cả cần header `Authorization: Bearer <Clerk session JWT>`)

| Method | Path | Mô tả |
|--------|------|--------|
| GET | `/api/v1/profile` | Profile (tạo mặc định nếu chưa có) |
| PUT | `/api/v1/profile` | Cập nhật `name`, `email`, `language`, `is_dark` |
| GET | `/api/v1/food-items` | Danh sách thực phẩm |
| POST | `/api/v1/food-items` | Một hoặc nhiều món (JSON array hoặc object) |
| PATCH | `/api/v1/food-items/:id` | Cập nhật món |
| DELETE | `/api/v1/food-items/:id` | Xóa món |
| GET | `/api/v1/saved-recipes` | Công thức đã lưu |
| POST | `/api/v1/saved-recipes` | Lưu / ghi đè công thức (`original_id`, `recipe_data`) |
| DELETE | `/api/v1/saved-recipes/:originalId` | Bỏ lưu |

Collections trên Atlas: `profiles`, `food_items`, `saved_recipes`.

---

## Deploy trên [Render](https://render.com)

Repo là **monorepo** (Flutter + `server/`). Trên Render bạn chỉ build **thư mục `server/`** (có `Dockerfile`).

### Tuỳ chọn: Blueprint (`render.yaml`)

Ở **root** repo có file **`render.yaml`** — trong Render chọn **New** → **Blueprint** → kết nối repo; sau đó điền secrets `MONGODB_URI` và `CLERK_SECRET_KEY` khi được hỏi. Tuỳ chỉnh `region` / `plan` trong file nếu cần.

### 1. Chuẩn bị (Web Service thủ công)

- Code đã push lên **GitHub** / **GitLab** / **Bitbucket** (Render kết nối repo).
- Atlas **Network Access** nên cho **`0.0.0.0/0`** (hoặc tương đương) để API trên Render gọi được cluster.

### 2. Tạo Web Service

1. Đăng nhập [Render Dashboard](https://dashboard.render.com) → **New +** → **Web Service**.
2. **Connect** repository chứa project này → chọn branch (vd. `main`).
3. Cấu hình:
   - **Name**: tuỳ bạn (vd. `harvest-hearth-api`).
   - **Region**: gần bạn (vd. Singapore).
   - **Root Directory**: đặt **`server`** — bắt buộc để Render chạy đúng `Dockerfile` và `package.json` trong `server/`.
   - **Runtime**: **Docker** (Render build từ `server/Dockerfile`; không cần Build / Start command riêng).
   - **Instance type**: **Free** (nếu còn) — lưu ý service free **ngủ** khi không có traffic; lần đầu sau idle có thể chậm vài chục giây.

### 3. Biến môi trường

Trong mục **Environment** của service, thêm:

| Key | Value |
|-----|--------|
| `MONGODB_URI` | URI Atlas (`mongodb+srv://...`) — nên đánh dấu **Secret**. |
| `CLERK_SECRET_KEY` | Secret key Clerk — **Secret**. |

Không cần thêm `PORT` — Render inject sẵn; app đã đọc `process.env.PORT`.

### 4. Deploy

**Create Web Service** → chờ build xong. URL dạng `https://harvest-hearth-api.onrender.com` (tên + region tuỳ bạn).

Mở trình duyệt: `https://<url-của-bạn>/health` → phải thấy `{"ok":true}`.

### 5. Flutter / APK

Trong `.env` (và khi build release):

```env
API_BASE_URL=https://<url-của-bạn>.onrender.com
```

(dùng **HTTPS**, không có dấu `/` ở cuối trừ khi bạn chủ định).

### 6. Gói Free — giảm “ngủ” (tuỳ chọn)

Dùng cron bên ngoài ([cron-job.org](https://cron-job.org), v.v.) gọi **`GET /health`** mỗi ~10 phút để service ít bị scale-to-zero lâu.

---

### Hosting khác (Docker giống trên)

Cùng một `Dockerfile` trong `server/`: đặt **root directory** = `server`, runtime **Docker**, env `MONGODB_URI` + `CLERK_SECRET_KEY`. Ví dụ: [Fly.io](https://fly.io), [Railway](https://railway.app), [Google Cloud Run](https://cloud.google.com/run), VPS + `docker run`.

### Kiểm tra Docker cục bộ

```bash
cd server
docker build -t harvest-api .
docker run --rm -p 8787:8787 -e PORT=8787 -e MONGODB_URI="..." -e CLERK_SECRET_KEY="..." harvest-api
```

Mở `http://localhost:8787/health`.
