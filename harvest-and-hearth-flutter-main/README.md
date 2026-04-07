<div align="center">

# Harvest & Hearth

**Ứng dụng Android quản lý thực phẩm thông minh** — theo dõi hạn sử dụng, gợi ý công thức từ AI, đồng bộ dữ liệu qua đám mây.  
Song ngữ **Việt – Anh**, giao diện **Material 3**.

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Android-API_24+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Clerk](https://img.shields.io/badge/Auth-Clerk-6C47FF)](https://clerk.com)
[![MongoDB](https://img.shields.io/badge/DB-MongoDB-47A248?logo=mongodb&logoColor=white)](https://mongodb.com)

</div>

---

## Mục lục

- [Tính năng](#features)
- [Tech stack](#tech-stack)
- [Phiên bản](#versioning)
- [Cài đặt nhanh](#quick-start)
- [Build bản phát hành (APK)](#build-release)
- [Cấu trúc dự án](#project-layout)
- [Kiến trúc](#architecture)
- [Backlog](#backlog)
- [Changelog](#changelog)

---

<a id="features"></a>
## Tính năng

| | |
| --- | --- |
| **Kho thực phẩm** | Tủ lạnh / Ngăn đông, tìm kiếm, sắp xếp, xem & chỉnh sửa. **Quét mã vạch / QR** bằng camera (đèn flash). |
| **Cảnh báo hết hạn** | Gom mặt hàng hết hạn & sắp hết hạn trên trang chủ; **thông báo định kỳ** (Android ~9:00); **widget** (Android — thêm thủ công từ màn hình chính). **Nút mô phỏng thời gian** (góc trái) để test thông báo; tắt bằng `ENABLE_TIME_SIMULATOR=false` trong `.env` khi build. |
| **AI Chef** | Groq (Llama 3.3) gợi ý 3 công thức từ nguyên liệu trong tủ; fallback **Gemini** nếu Groq lỗi. |
| **Khám phá** | Món Việt Nam (TheMealDB), tìm kiếm TheMealDB + DuckDuckGo, lưu công thức. |
| **Dịch** | Dịch tên/mô tả công thức theo ngôn ngữ đang dùng. |
| **Đám mây** | **MongoDB** qua API Node (`server/`) — đồng bộ kho & công thức đã lưu. |
| **Đăng nhập** | **Clerk** (email, OAuth… bật trong Clerk Dashboard; UI từ `clerk_flutter`). |
| **Cài đặt** | Sáng / tối, Việt / Anh — lưu cục bộ. |

---

<a id="tech-stack"></a>
## Tech stack

| Lớp | Công nghệ |
| --- | --- |
| UI | Flutter · Material 3 · **Provider** (ChangeNotifier) |
| Backend | **MongoDB** + REST API (`server/`) · **Clerk** JWT |
| AI | **Groq** `llama-3.3-70b-versatile` → **Gemini** `gemini-2.0-flash` |
| Công thức ngoài | TheMealDB, DuckDuckGo |
| Dịch | Google Translate (unofficial) |
| Quét mã | **mobile_scanner** (barcode + QR) |

---

<a id="versioning"></a>
## Phiên bản

| Nhãn sản phẩm | `pubspec` | Android `versionName` · `versionCode` |
| --- | --- | --- |
| **b0.4.3** | `1.0.15+16` | `1.0.15` · `16` |

**b0.3.2:** template Revolvapp Clerk + backlog template — [CHANGELOG](CHANGELOG.md).

Chi tiết từng bản: [**CHANGELOG.md**](CHANGELOG.md).

---

<a id="quick-start"></a>
## Cài đặt nhanh

**Yêu cầu:** Flutter SDK `>=3.6.2`, Android SDK **24+** (target **36**), project [Clerk](https://clerk.com), cluster [MongoDB](https://mongodb.com), API key **Groq** & **Gemini**.

```bash
git clone <repo-url>
cd harvest-and-hearth-flutter
flutter pub get
```

### 1. Backend API (MongoDB Atlas)

Trên [Atlas](https://cloud.mongodb.com) lấy **connection string** (`mongodb+srv://…`) và điền vào **`MONGODB_URI`** trong `server/.env` (sao chép từ `server/.env.example`).

```bash
cd server
cp .env.example .env   # MONGODB_URI=... (Atlas) + CLERK_SECRET_KEY — chi tiết: server/README.md
npm install
npm start
```

**Deploy cloud (Render):** xem **`server/README.md`** — mục *Deploy trên Render* (`Dockerfile`, **Root Directory** = `server`, secrets `MONGODB_URI` / `CLERK_SECRET_KEY`).

### 2. App Flutter

Tạo `.env` từ `.env.example` và điền:

```env
CLERK_PUBLISHABLE_KEY=pk_test_...
API_BASE_URL=http://localhost:8787
GROQ_API_KEY=<groq-key>
GEMINI_API_KEY=<gemini-key>
```

Trên **Android emulator**, `localhost` trỏ vào máy dev — dùng `http://10.0.2.2:8787` thay cho `localhost` nếu API chạy trên máy host.

```bash
flutter run
```

### Checklist vận hành (tối thiểu)

| Thành phần | Việc cần có |
| --- | --- |
| **Clerk** | Cùng một app: `CLERK_PUBLISHABLE_KEY` (Flutter `.env`) và `CLERK_SECRET_KEY` (Render / `server/.env`). Bật chiến lược đăng nhập (email, Google, …). |
| **API** | `API_BASE_URL` trỏ HTTPS API thật (vd. Render). `/health` phản hồi 200. |
| **MongoDB Atlas** | `MONGODB_URI` trên server; Network Access cho IP Render (hoặc `0.0.0.0/0` khi thử — siết lại sau). |
| **Google OAuth** (nếu dùng) | Client OAuth trên Google Cloud + redirect URI khớp Clerk; app: deep link `com.clerk.flutter://callback` trong allowlist mobile nếu cần. |
| **Email Clerk** | Template Revolvapp trong `clerk/email-templates/` đã dán trên Dashboard (Invitation, Verification code, …). |
| **Thông báo (Android)** | Lần đầu bật *Nhắc hạn* trong **Hồ sơ**, chấp nhận quyền thông báo (Android 13+). |

Thiếu một mục (ví dụ secret sai instance, API down, Atlas chặn IP) thì đăng nhập có thể thành công nhưng tải kho / lỗi 401 khi gọi API.

### Tài khoản thử trong APK

Chuẩn đề xuất (đặt trùng trong Clerk khi tạo user): **email** `test@harvestandhearth.app`, **mật khẩu** `!testPassword123!` (đủ yêu cầu phức tạp của Clerk).

1. **Clerk Dashboard** → **Users** → **Create user** (hoặc đăng ký một lần trong app) với cặp trên.  
2. Trong `.env` của bản build, thêm:
   `TEST_ACCOUNT_EMAIL` và `TEST_ACCOUNT_PASSWORD` (cùng giá trị).  
3. Build lại APK — trên màn đăng nhập sẽ có nút **Dùng tài khoản thử**: mở sheet hiển thị email/mật khẩu và **Sao chép** để dán vào form Clerk (SDK không cho điền sẵn form từ code an toàn).

Không đặt `TEST_*` thì nút ẩn; không nhúng mật khẩu trong repo công khai — chỉ trong `.env` build nội bộ.

---

<a id="build-release"></a>
## Build bản phát hành (APK)

```bash
flutter build apk --release
```

**Đầu ra APK** (`build/app/outputs/flutter-apk/`):

| File | Mô tả |
| --- | --- |
| `app-release.apk` | Bản build mặc định của Flutter |
| `harvestnhearth-<changelog>.apk` | Bản sao đặt tên theo **nhãn mới nhất** trong `CHANGELOG.md` (ví dụ `harvestnhearth-b0.4.3.apk`) |

**Icon launcher:** đặt PNG vuông tại [`code/app_icon.png`](code/app_icon.png), sau đó:

```bash
dart run flutter_launcher_icons
```

*(Tuỳ chọn Play Store: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.)*

---

<a id="project-layout"></a>
## Cấu trúc dự án

```
lib/
├── main.dart                    # App + ClerkAuth + theme tĩnh + MainShell
├── models/
├── providers/                   # AppProvider
├── constants/                   # translations, categories
├── services/                    # backend_api (HTTP + Clerk token), AI, search, translate
├── utils/
├── screens/                     # auth, dashboard, inventory, recipes, profile, barcode_scanner
└── widgets/                     # add_food_modal, cards, …
server/                          # API Node (MongoDB + Clerk JWT) — xem server/README.md
clerk/email-templates/           # HTML Handlebars dán vào Clerk Dashboard → Emails
render.yaml                      # Render Blueprint (tuỳ chọn) — deploy Docker từ server/
```

---

<a id="architecture"></a>
## Kiến trúc

- **Khởi động:** `ClerkAuth` → `AppProvider.init()` (prefs) → sau khi đăng nhập Clerk, `BackendApiService` gọi API với JWT session (HTTP có **timeout** cho cloud/cold start).
- **Điều hướng:** `IndexedStack` + `NavigationBar` — giữ state từng tab; FAB chỉ tab Kho.
- **AI:** `AiService` → thử Groq, lỗi thì Gemini.
- **Hiệu năng (b0.1.8):** `MaterialApp` không rebuild khi chỉ đổi dữ liệu kho/công thức; theme dùng instance tĩnh; ảnh TheMealDB decode có giới hạn kích thước cache.

---

<a id="backlog"></a>
## Backlog

- [x] Quét mã vạch và mã QR thực sự bằng camera
- [x] Thông báo nhắc nhở thực phẩm sắp hết hạn (local, 9:00)
- [ ] Danh sách mua sắm tự động từ kho thiếu
- [ ] Ảnh thực phẩm tuỳ chỉnh từ camera
- [x] Widget màn hình chính Android (cảnh báo)
- [ ] **Clerk:** Account locked, Password changed, Primary email changed, Reset password code, Sign in from new device — HTML có sẵn trong [`clerk/email-templates/`](clerk/email-templates/README.md); bật tính năng + dán template trên Dashboard (phiên bản sau).

---

<a id="changelog"></a>
## Changelog

Xem đầy đủ: [**CHANGELOG.md**](CHANGELOG.md).

---

<div align="center">

**Harvest & Hearth** · Quản lý tủ lạnh thông minh

</div>
