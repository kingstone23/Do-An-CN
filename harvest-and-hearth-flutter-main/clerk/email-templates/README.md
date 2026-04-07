# Email templates cho Clerk Dashboard

Clerk **không** dùng HTML email kiểu `<table>` thuần như nhiều ví dụ ngoài mạng. Editor trong Dashboard dùng **Revolvapp** (plugin Imperavi): markup kiểu **`<re-html>` / `<re-body>` / `<re-button>` …** — xem [Imperavi Revolvapp — Quick start](https://imperavi.com/legacy/revolvapp/docs/syntax/quick-start) và [Clerk — Email & SMS templates](https://clerk.com/docs/guides/customizing-clerk/email-sms-templates).

Handlebars vẫn dùng cho biến (`{{app.name}}`, `{{action_url}}`, `{{#if inviter_name}}` …). Một số partial của Clerk (ví dụ **`{{> app_logo}}`**) chỉ hoạt động trong editor Revolvapp.

## Logo app (`{{> app_logo}}`)

Bạn **không** tự viết HTML logo trong file template. `{{> app_logo}}` là **partial** do Clerk render — nội dung lấy từ **branding** của ứng dụng.

1. Vào **[Clerk Dashboard](https://dashboard.clerk.com)** → chọn **Application** (instance đúng dev/prod).
2. Mục **Branding** / **Customize** (tên menu có thể là *Branding*, *Customization*, *Configure* — tùy bản Dashboard): tải lên **Logo** hoặc dán **URL ảnh** (PNG/SVG, nền trong suốt thường đẹp hơn trong email).
3. Lưu. Biến **`{{app.logo_image_url}}`** trong tài liệu Clerk cũng trỏ cùng URL đó.
4. Trong **Emails** → **Preview**, phần `{{> app_logo}}` sẽ hiện logo thật; nếu chưa cấu hình logo, có thể chỉ thấy tên app hoặc placeholder — kiểm tra lại bước 2.

Nếu muốn **bỏ** partial và tự chèn ảnh tĩnh: thay `{{> app_logo}}` bằng thẻ Revolvapp hợp lệ (ví dụ `re-image` nếu editor hỗ trợ) hoặc dùng biến `{{app.logo_image_url}}` trong một `re-text` / link — cách mặc định vẫn nên giữ `{{> app_logo}}` để đồng bộ với Clerk.

## Cách dán

1. **Clerk Dashboard** → **Customization** → **[Emails](https://dashboard.clerk.com/~/customization/email)** → chọn template (ví dụ **Invitation**).
2. Trong editor, dùng chế độ hiển thị markup **Revolvapp** (thường là **HTML mode** / source tương đương — đừng dán HTML `<!DOCTYPE html>` kiểu web thường).
3. Thay toàn bộ nội dung bằng file tương ứng trong repo này → **Preview**.

Nếu Preview lỗi, so sánh với bản mặc định của Clerk (nút **Reset**) rồi chỉ lớp `re-*` / màu / chữ — giữ nguyên **tên biến** mà Clerk cung cấp trong template gốc.

## Biến quan trọng (Invitation)

Theo template mặc định Clerk, tên người mời là **`inviter_name`** (không phải `inviter.name`), kèm helper **`{{escapeURIs inviter_name}}`** trong điều kiện `{{#if inviter_name}}`.

| File | Template Dashboard | Biến / partial chính |
| --- | --- | --- |
| [invitation.html](invitation.html) | **Invitation** | `{{> app_logo}}`, `inviter_name`, `invitation.expires_in_days`, `{{action_url}}`, `{{current_year}}` |
| [verification-code.html](verification-code.html) | **Verification code** | `{{> app_logo}}`, `{{{otp_code}}}`, `{{current_year}}` — nếu Preview không nhận `otp_code`, chọn đúng biến mã trong nút **Variable** của template đó |
| [account-locked.html](account-locked.html) | **Account locked** | `{{> app_logo}}`, `{{action_url}}`, `{{current_year}}` |
| [password-changed.html](password-changed.html) | **Password changed** | `{{> app_logo}}`, `{{action_url}}` |
| [primary-email-changed.html](primary-email-changed.html) | **Primary email address changed** | `{{> app_logo}}`, `{{action_url}}` |
| [reset-password-code.html](reset-password-code.html) | **Reset password code** | `{{> app_logo}}`, `{{{otp_code}}}` — kiểm tra tên biến mã trong **Variable** |
| [sign-in-from-new-device.html](sign-in-from-new-device.html) | **Sign in from new device** | `{{> app_logo}}`, `{{action_url}}` |

Tất cả file trên dùng cùng định dạng **Revolvapp** (`<re-html>` …), không dùng `<!DOCTYPE html>` / `<table>` email cổ điển.

## Đăng nhập bằng mã email (OTP)

1. **User & Authentication** → bật **Email verification code** cho luồng cần dùng.
2. Template **Verification code** → dán [verification-code.html](verification-code.html).

## Gợi ý subject (tuỳ chỉnh trong từng template)

| Template | Subject (VN) gợi ý |
| --- | --- |
| Invitation | `Lời mời tham gia {{app.name}}` |
| Verification code | `Mã xác thực {{app.name}}` |
| Account locked | `Tài khoản {{app.name}}` |
| Password changed | `Mật khẩu {{app.name}} đã đổi` |
| Primary email changed | `Email tài khoản {{app.name}} đã thay đổi` |
| Reset password code | `Mã đặt lại mật khẩu {{app.name}}` |
| New device | `Đăng nhập mới — {{app.name}}` |
