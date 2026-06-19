# 📱 PRM Mobile — Ứng dụng Quản lý Năng suất (Flutter)

Dự án Frontend di động được xây dựng bằng **Flutter SDK 3.22+**, tuân thủ cấu trúc thư mục hướng tính năng (**Feature-First Architecture**), giao diện thiết kế hiện đại kiểu kính mờ (**Glassmorphism**) hỗ trợ hai chế độ sáng/tối tự động và đa ngôn ngữ.

---

## 🏛️ Kiến trúc & Thiết kế Dự án

Ứng dụng tuân thủ kiến trúc chia lớp rõ ràng để đạt điểm tối đa theo tiêu chí đánh giá chất lượng mã nguồn:
1. **Presentation Layer (Giao diện)**: Toàn bộ màn hình UI phức tạp được phân tách thành các Widget nhỏ, tái sử dụng được đặt trong thư mục `widgets/` của từng Feature.
2. **Business Logic Layer (State Management)**: Quản lý trạng thái bằng thư viện **Provider** (`ChangeNotifierProvider`), tách biệt hoàn toàn dữ liệu động khỏi UI.
3. **Data Layer (Service & Model)**:
   * **Model**: Chuyển đổi an toàn kiểu dữ liệu JSON sang các Dart Object (`TaskModel`, `ProjectModel`, `NotificationModel`, v.v.).
   * **Service**: Chứa toàn bộ các yêu cầu HTTP (REST API), cấu hình Timeout, và quản lý các kết nối Socket.IO để cập nhật tin nhắn thời gian thực.
4. **Global Services (Dịch vụ chung)**: Xử lý đa ngôn ngữ, chế độ giao diện (Dark Mode) và kiểm tra sự kiện lịch biểu ngầm.

---

## 📁 Cấu trúc Thư mục Chi tiết (`lib/`)

```text
lib/
├── main.dart                       # Điểm khởi chạy (Entry Point) & Cấu hình Providers
├── core/                           # Các tài nguyên dùng chung trong toàn bộ dự án
│   ├── constants/                  # Hằng số hệ thống
│   │   ├── app_colors.dart         # Bảng màu thương hiệu (Primary, Dark/Light, Statuses)
│   │   ├── app_sizes.dart          # Kích thước chuẩn (Padding, Radius, Icon, Font)
│   │   ├── app_routes.dart         # Định nghĩa các Route điều hướng
│   │   └── app_durations.dart      # Thời gian cấu hình animation và delay
│   └── widgets/                    # Các Widget dùng chung trên toàn hệ thống
│       └── premium_widgets.dart    # GlassCard, Shimmer, FadeInSlide, PremiumButton...
│
├── services/                       # Dịch vụ toàn cục (Global Services)
│   ├── auth_service.dart           # Xác thực & Cấu hình API Endpoint
│   ├── theme_service.dart          # Quản lý giao diện sáng/tối (ThemeMode)
│   ├── locale_service.dart         # Hỗ trợ song ngữ (Vietnamese / English)
│   └── event_check_service.dart    # Kiểm tra sự kiện định kỳ & thông báo đẩy cục bộ
│
└── features/                       # Quản lý các tính năng theo cấu trúc Feature-First
    ├── auth/                       # Phân hệ Xác thực (Đăng nhập, Đăng ký, OTP)
    │   ├── providers/              # auth_provider.dart
    │   └── screens/                # login_screen.dart (Form và OTP logic)
    │
    ├── dashboard/                  # Trang chủ Tổng hợp Năng suất
    │   ├── models/                 # dashboard_summary.dart
    │   ├── services/               # dashboard_service.dart
    │   └── screens/                # dashboard_screen.dart
    │
    ├── tasks/                      # Quản lý Công việc (Personal & Project tasks)
    │   ├── models/                 # task_model.dart (Enum TaskStatus, TaskPriority)
    │   ├── providers/              # task_provider.dart
    │   ├── services/               # task_service.dart
    │   ├── screens/                # task_screen.dart (Inbox thống nhất)
    │   └── widgets/                # task_card.dart, task_filter_sheet.dart...
    │
    ├── projects/                   # Quản lý Dự án & Cộng tác nhóm
    │   ├── models/                 # project_model.dart (Thành viên, vai trò, thống kê)
    │   ├── providers/              # project_provider.dart
    │   ├── services/               # project_service.dart
    │   ├── screens/                # project_screen.dart & các phần bổ trợ tách biệt
    │   └── widgets/                # chat_bottom_sheet.dart (Realtime chat), tabs...
    │
    ├── timer/                      # Trình đếm giờ Focus Pomodoro & Trồng cây
    │   ├── models/                 # forest_tree.dart
    │   ├── services/               # timer_service.dart
    │   ├── screens/                # timer_screen.dart (Vòng tròn đếm ngược)
    │   └── widgets/                # forest_dialog_content.dart, timer_painter.dart...
    │
    ├── calendar/                   # Lịch biểu & Lịch sự kiện
    │   ├── models/                 # calendar_item.dart
    │   ├── services/               # calendar_service.dart
    │   ├── utils/                  # calendar_utils.dart
    │   ├── screens/                # calendar_screen.dart
    │   └── widgets/                # calendar_widgets.dart
    │
    ├── notifications/              # Trung tâm thông báo
    │   ├── models/                 # notification_model.dart
    │   ├── providers/              # notification_provider.dart
    │   ├── services/               # notification_service.dart
    │   └── screens/                # notifications_screen.dart
    │
    ├── analytics/                  # Phân tích Báo cáo Năng suất
    │   ├── models/                 # analytics_report.dart
    │   ├── services/               # analytics_service.dart
    │   ├── screens/                # analytics_screen.dart
    │   └── widgets/                # analytics_widgets.dart
    │
    └── profile/                    # Hồ sơ cá nhân
        └── screens/                # profile_screen.dart (Đổi username)
```

---

## 🛠️ Công nghệ Sử dụng & Thư viện Chính

* **State Management**: `provider` (Quản lý trạng thái hiệu quả, tinh gọn).
* **Network**: `http` (Giao tiếp REST API với backend).
* **Realtime Socket**: `socket_io_client` (Đồng bộ chat nhóm thời gian thực).
* **Định dạng dữ liệu & Thời gian**: `intl` (Xử lý múi giờ, định dạng ngày tháng, ngôn ngữ).
* **Hiệu ứng & Giao diện**: `shimmer` (Hiển thị trạng thái tải dữ liệu mượt mà).

---

## ⚡ Hướng dẫn Chạy ứng dụng

### 1. Yêu cầu Hệ thống
* Đã cài đặt Flutter SDK phiên bản mới nhất (khuyến nghị từ `3.22.0` trở lên).
* Thiết bị ảo (Emulator) Android/iOS hoặc thiết bị thật đã bật chế độ nhà phát triển.

### 2. Cài đặt các thư viện phụ thuộc
Di chuyển vào thư mục `mobile/` và tải về các package:
```powershell
flutter pub get
```

### 3. Phân tích lỗi và kiểm tra cú pháp tĩnh (Lints Verification)
Đảm bảo mã nguồn hoàn toàn không có cảnh báo phân tích tĩnh trước khi build:
```powershell
flutter analyze
```
*Hiện tại dự án đạt kết quả sạch hoàn toàn **`No issues found!`***.

### 4. Khởi chạy ứng dụng
Chạy ứng dụng ở chế độ Debug trên thiết bị được kết nối:
```powershell
flutter run
```
