# FlowMate Productivity System - System Specification

Tài liệu đặc tả toàn bộ tính năng và vai trò (Role/Actor) của hệ thống **FlowMate Productivity System (v1.0)**. Được phát triển và hoàn thiện bởi **Group 3**.

*Xem thêm tài liệu kiến trúc & vận hành:*
- Tài liệu tổng hợp toàn diện: `[[FlowMate_Master_Specification]]`
- Hướng dẫn cài đặt & Khởi động dự án: `[[README]]`


---

## 1. Các Vai Trò Trong Hệ Thống (Roles & Actors)

Hệ thống FlowMate được thiết kế xoay quanh sự cộng tác và cá nhân hóa năng suất. Hệ thống gồm **3 nhóm Actor chính**:

### Actor 1: Thành viên thông thường (User / Member)
Là người sử dụng hệ thống để quản lý hiệu suất cá nhân và tham gia vào các dự án.
- **Mục tiêu**: Tập trung làm việc, theo dõi công việc cá nhân, tham gia cuộc họp, ghi nhận Pomodoro và theo dõi tiến trình.
- **Quyền hạn**:
  - Quản lý hồ sơ cá nhân và cấu hình ứng dụng.
  - Xem Dashboard cá nhân.
  - Tạo, cập nhật, xóa các công việc (Tasks) cá nhân hoặc các công việc được giao trong dự án.
  - Tham gia dự án (khi được add vào), xem tiến độ dự án.
  - Ghi nhận lịch trình cá nhân (Calendar Events), nhắc nhở (Reminders).
  - Thực hiện các phiên đếm ngược Pomodoro (Focus Sessions) để hệ thống tự động đồng bộ thời gian tập trung.
  - Nhận và đọc các thông báo nhắc nhở (Notifications).

### Actor 2: Trưởng nhóm / Quản lý dự án (Project Manager / Leader)
Là người khởi tạo và dẫn dắt các dự án cộng tác trong hệ thống.
- **Mục tiêu**: Phân chia công việc, theo dõi tiến độ tổng quan của dự án và các thành viên, tối ưu hiệu suất nhóm.
- **Quyền hạn**:
  - Có toàn bộ quyền hạn của một **Thành viên thông thường**.
  - Khởi tạo dự án mới (Create Project) và cập nhật thông tin dự án.
  - Thêm thành viên vào dự án bằng Email (Add Members).
  - Tạo Task cho dự án và gán (Assign) cho các thành viên cụ thể.
  - Theo dõi tiến độ phần trăm (%) hoàn thành dự án dựa trên số lượng Task đã hoàn thành (Hệ thống tự động tính KPI).
  - Lên lịch cuộc họp (Meetings) cho dự án để hiển thị đồng bộ lên lịch của tất cả thành viên tham gia.

### Actor 3: Quản trị viên hệ thống (System Administrator)
Là người vận hành và đảm bảo tính ổn định của hệ thống FlowMate.
- **Mục tiêu**: Bảo mật dữ liệu, giám sát tài nguyên API, quản lý tài khoản người dùng.
- **Quyền hạn**:
  - Truy cập toàn bộ cơ sở dữ liệu (thông qua Database Console/Mongo Atlas).
  - Giám sát hiệu năng hoạt động của Cloud Backend (Vercel).
  - Kiểm tra và quản lý API tài liệu hóa thông qua Swagger UI.

---

## 2. Bản Đồ Tính Năng Hệ Thống (System Features Map)

FlowMate được tích hợp đồng bộ giữa **Node.js Express Backend** (Deploy trên Vercel) và **Flutter Mobile App** (Android/iOS) thông qua **8 phân hệ tính năng cốt lõi**:

### Phân Hệ 1: Xác Thực & Hồ Sơ (Authentication & Profile)
Quản lý quyền truy cập bảo mật qua cơ chế Token JWT (JSON Web Token).
- **Đăng ký (`POST /api/auth/register`)**: Tạo tài khoản mới bằng Email, Số điện thoại và Mật khẩu.
- **Đăng nhập (`POST /api/auth/login`)**: Nhận diện Email/Số điện thoại và mật khẩu, trả về mã Access Token để xác thực các API sau.
- **Hồ sơ cá nhân (`GET /api/users/profile`)**: Lấy thông tin cá nhân bao gồm Tên hiển thị, Bio, Avatar, Cấu hình thời gian đếm ngược mặc định.
- **Cập nhật hồ sơ (`PUT /api/users/profile`)**: Cho phép người dùng thay đổi Bio, đổi tên hoặc điều chỉnh thời gian Pomodoro tùy chọn (Thời gian tập trung, thời gian nghỉ ngắn, nghỉ dài).

### Phân Hệ 2: Bảng Điều Khiển Năng Suất (Dashboard)
Điểm hội tụ dữ liệu hiển thị tức thì ngay sau khi đăng nhập để người dùng nắm bắt ngày làm việc.
- **Thống kê nhanh (`GET /api/dashboard/summary`)**:
  - Số lượng công việc còn nợ chưa làm (Pending Tasks).
  - Số lượng công việc đã hoàn thành xuất sắc (Completed Tasks).
  - Số lượng dự án đang tham gia tích cực (Projects).
  - Tổng số phút tập trung tích lũy trong ngày hôm nay (Focus minutes today).
- **Lịch họp khẩn cấp**: Hiển thị chi tiết cuộc họp tiếp theo (Next Meeting) sắp diễn ra trong ngày để người dùng không bỏ lỡ.

### Phân Hệ 3: Quản Lý Công Việc (Task Management)
Hỗ trợ đầy đủ các thao tác CRUD công việc hàng ngày.
- **Tạo mới**: Thiết lập Tiêu đề, Mô tả, Mức độ ưu tiên (Low, Medium, High), Hạn chót (Due Date), Nhãn (Labels) và liên kết dự án (nếu có).
- **Danh sách & Bộ lọc**: Xem danh sách công việc cá nhân hoặc theo dự án. Hỗ trợ lọc theo Trạng thái (Pending / Completed), tìm kiếm theo Tên công việc.
- **Cập nhật & Đánh dấu hoàn thành**: Đổi trạng thái từ Chưa hoàn thành sang Đã hoàn thành (Trigger tính toán lại tiến độ dự án).
- **Xóa**: Loại bỏ công việc khỏi hệ thống khi không cần thiết.

### Phân Hệ 4: Quản Lý Dự Án (Project Management)
Tạo không gian làm việc cộng tác nhóm hiệu quả với tính năng tự động hóa và thời gian thực.
- **Tạo dự án**: Khởi tạo dự án kèm Tên, Mô tả chi tiết và Hạn chót của dự án. Người khởi tạo tự động giữ quyền **Project Leader / Manager**.
- **Quản lý thành viên (Add Members)**: Project Leader thêm các thành viên tham gia thông qua việc nhập Email của họ. Backend tự động map ID và đưa thành viên vào nhóm.
- **Theo dõi tiến độ (KPI Progress)**: Hệ thống tự động quét số lượng Task thuộc dự án và tính toán phần trăm (%) hoàn thành để hiển thị thanh Progress Bar sinh động trên Mobile.
- **Danh sách Tasks theo Project**: Xem tất cả các công việc được phân chia cụ thể trong từng dự án, phân công rõ ràng cho từng thành viên (Assignee).

> [!NOTE]
> **Luồng Cộng Tác & Cơ Chế Tự Động Tính Tiến Độ (Real-time KPI Workflow):**
> 1. **Phân Quyền Tự Động**: Khi bất kỳ thành viên nào tạo dự án, họ trở thành **Leader (Manager)**. Chỉ Leader mới có quyền mời thành viên và giao Task.
> 2. **Liên Kết & Đồng Bộ**: Khi Leader mời thành viên bằng Email, dự án sẽ ngay lập tức xuất hiện trên tab **Projects** của thành viên đó sau khi họ đăng nhập.
> 3. **Công Thức Tính Tiến Độ Tự Động**: Hệ thống tự động đo lường dựa trên hiệu suất thực tế của nhóm:
>    $$\text{Tiến độ Dự án (\%)} = \left( \frac{\text{Số lượng Tasks đã hoàn thành (Completed)}}{\text{Tổng số Tasks được tạo thuộc dự án đó}} \right) \times 100$$
> 4. **Đồng Bộ Thời Gian Thực (Real-time Sync)**: Khi bất kỳ thành viên nào (hoặc Leader) hoàn thành một công việc được giao và tích chọn **Đã hoàn thành**, thanh tiến độ của dự án sẽ tự động tính toán lại ở Backend và **cập nhật tức thời** lên màn hình di động của toàn bộ thành viên trong dự án!

### Phân Hệ 5: Lịch Trình & Sự Kiện (Calendar & Schedule)
Thời gian biểu tích hợp đa nguồn giúp sắp xếp công việc khoa học.
- **Gộp chung thông minh (`GET /api/calendar/events`)**: Tự động gộp dữ liệu từ 3 nguồn:
  1. Các cuộc họp (Meetings) được lên lịch.
  2. Các nhắc nhở cá nhân (Reminders) tự tạo.
  3. Thời hạn chót (Due Date) của tất cả các Tasks chưa hoàn thành.
- **Tạo sự kiện**: Chọn Ngày & Giờ cụ thể, tiêu đề, loại sự kiện (Meeting, Reminder, Other) trực quan ngay trên App.
- **Xóa sự kiện**: Hủy các nhắc nhở/lịch trình cá nhân.

### Phân Hệ 6: Đếm Ngược Tập Trung (Focus Session - Pomodoro)
Công cụ hỗ trợ rèn luyện sự tập trung cao độ dựa trên phương pháp khoa học Pomodoro.
- **Đếm ngược Space Timer**: Đồng hồ đếm ngược với giao diện Space Timer hoạt họa tuyệt đẹp, tương ứng với 4 chế độ: Focus (25 phút), Short Break (5 phút), Long Break (15 phút), và Custom (tự chỉnh).
- **Đồng bộ Online (`POST /api/sessions`)**: Khi kết thúc một phiên đếm ngược thành công, thời gian focus sẽ được tự động gửi lên backend để lưu trữ vào lịch sử.
- **Chế độ lưu trữ Offline**: Nếu mất kết nối internet, ứng dụng di động sẽ tự động ghi nhận phiên hoàn thành ngoại tuyến để tránh làm mất dữ liệu của người dùng.
- **Báo cáo lịch sử**: Xem danh sách các phiên tập trung gần đây nhất.

### Phân Hệ 7: Thông Báo & Nhắc Nhở (Notifications)
Đảm bảo người dùng luôn đi đúng lộ trình và không quên nhiệm vụ.
- **Danh sách thông báo (`GET /api/notifications`)**: Hiển thị các thông báo từ hệ thống, nhắc nhở công việc sắp hết hạn hoặc lời mời tham gia dự án mới.
- **Đánh dấu đã đọc (`PUT /api/notifications/:id/read`)**: Giúp hộp thư thông báo luôn sạch sẽ gọn gàng.

### Phân Hệ 8: Báo Cáo & Phân Tích (Analytics & Reports)
Công cụ giúp phản hồi hiệu suất dài hạn cho người dùng.
- **Thống kê năng suất (`GET /api/analytics/productivity`)**:
  - Phân tích tỷ lệ hoàn thành công việc đúng hạn.
  - Thống kê thời gian tập trung (Focus Time) biểu diễn theo các ngày trong tuần/tháng để làm cơ sở vẽ biểu đồ cột trực quan trên frontend.

---

## 3. Kiến Trúc Công Nghệ Áp Dụng (Technology Stack)

- **Frontend (Mobile)**: **Flutter** (Dart) - Giao diện Premium Cyber Dark Mode, tích hợp Glassmorphism mờ mượt mà, sử dụng State Management chuẩn mực, kết nối HTTPS/WSS với Backend.
- **Backend (API)**: **Node.js** & **Express** - Xây dựng kiến trúc RESTful API chuẩn chỉ, phân tách tầng Controller/Router rõ ràng, bảo mật JWT. Deploy trực tuyến trên môi trường Serverless của **Vercel**.
- **Database**: **MongoDB Atlas** - Cơ sở dữ liệu đám mây NoSQL hoạt động ổn định, kết nối thông qua ODM **Mongoose**.
- **Tài liệu hóa**: **Swagger UI** (OpenAPI 3.0) tích hợp trực tiếp giúp các lập trình viên dễ dàng thử nghiệm API trực quan.
