# Greenly Admin

Ứng dụng Flutter quản lý sản phẩm, dùng chung giao diện cho web và Android.
Luồng đăng nhập, tìm kiếm, thêm, sửa, xóa và API được giữ nguyên.

## Chạy ứng dụng

Khởi động backend theo cấu hình hiện có trong `backend/.env`, sau đó:

```powershell
flutter pub get
flutter run -d chrome --web-port 8080
flutter run -d emulator-5554
```

API mặc định: `127.0.0.1:3000` trên web và `10.0.2.2:3000` trên giả lập Android.
Android cho phép HTTP tới riêng địa chỉ giả lập `10.0.2.2` ở bản phát hành.
Thiết bị Android thật cần một backend có thể truy cập và cấu hình `--dart-define=API_URL=https://<host>/api/products`.

## Kiểm thử và build

Chạy các lệnh Flutter tuần tự để tránh ghi đè file đăng ký plugin giữa các bản build.

```powershell
flutter analyze
flutter test
.\test_web.ps1
flutter test integration_test/app_test.dart -d emulator-5554
flutter build web --release --no-web-resources-cdn
flutter build apk --release
```

`test_web.ps1` khắc phục lỗi phục vụ CanvasKit của bộ chạy test Flutter 3.47 trên Windows bằng hai tài nguyên có sẵn trong SDK; tự xóa tài nguyên tạm sau khi chạy.

Các test dùng API giả lập, không sửa dữ liệu thật: kiểm tra nhiều kích thước màn hình, màn hình ngang, bàn phím mở, chữ lớn, lỗi tải/thử lại, tìm kiếm, xác nhận xóa và lưu thông tin. Test trên Android kiểm tra luồng đăng nhập → tìm kiếm → sửa → xóa → đăng xuất. Việc chọn ảnh từ thư viện thiết bị và kết nối MongoDB thật cần kiểm tra với môi trường thực tế.

Đầu ra: `build/web` và `build/app/outputs/flutter-apk/app-release.apk`.
