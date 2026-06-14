# Flutter Development Guide (Android Focus)

Chào ông chủ, đây là tài liệu hướng dẫn nhanh để ông làm chủ dự án Flutter này.

## 1. Cấu trúc thư mục (Feature-based Architecture)
Chúng ta nên tổ chức code theo tính năng để dễ quản lý khi dự án lớn dần.

- `lib/core/`: Chứa các thành phần dùng chung (theme, constants, network config).
- `lib/features/`: Mỗi folder con là một tính năng (vd: `auth`, `task_list`).
  - `screens/`: Các màn hình UI.
  - `widgets/`: Các component nhỏ.
  - `models/`: Định nghĩa kiểu dữ liệu.
  - `providers/`: Quản lý logic/state (nếu dùng Riverpod).

## 2. Các Widget cơ bản thường dùng
- **StatelessWidget**: Dùng cho UI không thay đổi (icon, label, button tĩnh).
- **StatefulWidget**: Dùng khi UI cần cập nhật (form nhập liệu, danh sách có thể thay đổi).
- **Scaffold**: Bộ khung chuẩn của một màn hình (có AppBar, Body, FloatingActionButton).
- **Container, Column, Row**: Các widget để dàn trang (Layout).

## 3. Quản lý trạng thái (State Management)
Tôi khuyến nghị sử dụng **Riverpod** vì tính an toàn và dễ test.

### Cài đặt:
Thêm vào `pubspec.yaml`:
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
```

### Cách dùng cơ bản:
```dart
// 1. Khai báo provider
final counterProvider = StateProvider((ref) => 0);

// 2. Sử dụng trong Widget (phải kế thừa ConsumerWidget)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

## 4. Kết nối Backend (Networking)
Sử dụng thư viện `dio` để có hiệu năng tốt và interceptors mạnh mẽ.

### Cài đặt:
```yaml
dependencies:
  dio: ^5.4.0
```

### Lưu ý quan trọng cho Android Emulator:
Khi gọi API từ Emulator tới Backend đang chạy trên máy tính (localhost), hãy dùng URL:
- `http://10.0.2.2:<port>/api/...` (thay vì `localhost`).

## 5. Các lệnh Terminal hữu ích
- `flutter pub get`: Tải và cập nhật các thư viện mới.
- `flutter run`: Chạy ứng dụng trên thiết bị đang kết nối.
- `flutter clean`: Xóa bộ nhớ đệm build (dùng khi gặp lỗi lạ).
- `flutter format .`: Tự động format code cho sạch đẹp.

## 6. Mẹo nhỏ (Tips)
- Sử dụng phím tắt `r` (Hot Reload) hoặc `R` (Hot Restart) trong terminal khi đang `flutter run` để xem thay đổi ngay lập tức mà không cần build lại từ đầu.
- Luôn kiểm tra `pub.dev` để tìm kiếm các thư viện hữu ích khác.

---
Ông chủ cần tôi demo chi tiết phần nào (ví dụ: tạo Form đăng nhập hay List hiển thị dữ liệu) không?
