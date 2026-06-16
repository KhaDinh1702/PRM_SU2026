# Ke Hoach Phan Chia Hoc Docs FlowMate

Bang phan chia nhiem vu nghien cuu va hoc tai lieu thiet ke he thong (Master Specification va System Specification) cho cac thanh vien trong nhom.

| Thanh vien | Vai tro | Noi dung can hoc | Chi tiet va Muc tieu | Do kho |
| --- | --- | --- | --- | --- |
| Kha | Fullstack | - Kien truc Backend (Express MVC)<br>- MongoDB Schemas<br>- Project Controller & Socket.IO | - Hieu kien truc thuc muc be/src<br>- Nam ro quan he giua User, Project, Task, Message Schemas<br>- Hieu co che broadcast real-time KPI qua Socket.IO | Cao |
| Hung | Fullstack | - Auth Service & API Security<br>- Session Controller (Pomodoro)<br>- Analytics Controller | - Co che ma hoa, bam mat khau va cap JWT Token<br>- Luong dong bo Session khi online/offline<br>- Logic aggregate du lieu thong ke nang suat | Cao |
| Long | Frontend | - Kien truc Flutter Mobile App<br>- Core Services (Theme, Locale)<br>- Project Screen & Real-time KPI | - Kien truc Clean Architecture theo Features trong frontend<br>- Trinh dieu khien toan cuc (theme, storage, localization)<br>- Ket noi Socket.IO o mobile de cap nhat KPI | Trung binh |
| Bao | Frontend | - Calendar Screen & Unified Events<br>- Timer Screen (Pomodoro)<br>- Analytics Screen UI | - TableCalendar va logic gop su kien tu 3 nguon (Meeting, Task, Event)<br>- Giao dien Space Timer va dong bo session<br>- Ve bieu do nang suat (cot va tron) | Trung binh |
| Dat | Frontend | - Auth Screen (Login/Register Form)<br>- Profile Screen (Username update)<br>- Notifications Screen | - Form dang nhap, dang ky va validate phia client<br>- Thay doi thong tin ca nhan, cap nhat username phia client<br>- Hien thi danh sach thong bao va gui request danh dau da doc | De |

---

## Chi Tiet Cac Doan Code Cu The Cho Tung Thanh Vien Tu Hoc

### 1. Kha (Fullstack)
* **Cấu hình server & kết nối WebSocket:**
  * **File:** [server.js](file:///c:/Users/user/Desktop/PRM/be/src/server.js)
  * **Dòng code & logic cụ thể (Dòng 99-132):**
    ```javascript
    io.on('connection', (socket) => {
        console.log('User connected to socket:', socket.id);

        socket.on('joinProject', (projectId) => {
            socket.join(projectId);
            console.log(`Socket ${socket.id} joined project room: ${projectId}`);
        });

        socket.on('sendMessage', async (data) => {
            try {
                const { projectId, senderId, text } = data;
                
                // Save to database
                const newMessage = new Message({
                    project: projectId,
                    sender: senderId,
                    text: text
                });
                await newMessage.save();
                await newMessage.populate('sender', 'name email profile');
                io.to(projectId).emit('receiveMessage', newMessage);
            } catch (error) {
                console.error('Error saving/sending message:', error);
            }
        });
    });
    ```
* **Thiết kế Database (Mongoose models):**
  * **File:** [Project.js](file:///c:/Users/user/Desktop/PRM/be/src/models/Project.js)
    * **Đoạn định nghĩa Schema cốt lõi:**
      ```javascript
      members: [{ type: Schema.Types.ObjectId, ref: 'User' }],
      memberRoles: [{
          user: { type: Schema.Types.ObjectId, ref: 'User' },
          role: { type: String, enum: ['Owner', 'Manager', 'Member'], default: 'Member' }
      }]
      ```
  * **File:** [Task.js](file:///c:/Users/user/Desktop/PRM/be/src/models/Task.js)
    * **Đoạn phân loại nguồn task:**
      ```javascript
      sourceType: { type: String, enum: ['personal', 'project'], default: 'personal' },
      project: { type: Schema.Types.ObjectId, ref: 'Project', default: null },
      assignedTo: { type: Schema.Types.ObjectId, ref: 'User', default: null }
      ```
* **Logic tính toán KPI tự động & Socket Event:**
  * **File:** [projectController.js](file:///c:/Users/user/Desktop/PRM/be/src/controllers/projectController.js)
  * **Dòng code & công thức cụ thể (Dòng 157-160):**
    * **Công thức tính KPI dự án:**
      $$\text{Progress \%} = \text{Round}\left( \frac{\text{Số Tasks đã hoàn thành}}{\text{Tổng số Tasks}} \times 100 \right)$$
    * **Đoạn code Mongoose cụ thể:**
      ```javascript
      const totalTasks = await Task.countDocuments({ project: projectId });
      const completedTasks = await Task.countDocuments({ project: projectId, status: 'Completed' });
      const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
      ```
  * **Đoạn code bắn tin real-time sang Client (Dòng 574-577):**
    ```javascript
    const io = req.app.get('io');
    if (io) {
        io.to(projectId.toString()).emit('taskUpdated', task);
    }
    ```

### 2. Hưng (Fullstack)
* **Auth Controller (Register/Login):**
  * **File:** [authController.js](file:///c:/Users/user/Desktop/PRM/be/src/controllers/authController.js)
  * **Đoạn xử lý sinh mã JWT Token khi Đăng nhập:**
    ```javascript
    const token = jwt.sign(
        { id: user._id, name: user.name, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
    );
    res.status(200).json({ token, user: { id: user._id, name: user.name, email: user.email } });
    ```
* **Middleware bảo mật API:**
  * **File:** [authMiddleware.js](file:///c:/Users/user/Desktop/PRM/be/src/middleware/authMiddleware.js) (hoặc tương đương)
  * **Logic kiểm tra Headers:**
    ```javascript
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Truy cập bị từ chối' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    ```
* **Analytics & Gom nhóm dữ liệu (Aggregation):**
  * **File:** [analyticsController.js](file:///c:/Users/user/Desktop/PRM/be/src/controllers/analyticsController.js)
  * **Đoạn code Mongoose Aggregate lọc hiệu suất:**
    ```javascript
    const sessions = await Session.aggregate([
        { $match: { user: userId, createdAt: { $gte: startDate } } },
        { $group: { _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } }, totalSeconds: { $sum: "$durationSeconds" } } }
    ]);
    ```

### 3. Long (Frontend)
* **Main Navigation & LifeCycle:**
  * **File:** [main.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/main.dart)
  * **IndexedStack điều hướng (Dòng 293-299):**
    ```dart
    child: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    ),
    ```
* **Theme & Locale Service:**
  * **File:** [theme_service.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/services/theme_service.dart)
  * **Lắng nghe thay đổi theme cục bộ:**
    ```dart
    static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);
    static void toggleTheme() {
        isDarkMode.value = !isDarkMode.value;
    }
    ```
* **Kết nối WebSocket Client bên Flutter:**
  * **File:** [chat_bottom_sheet.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/projects/widgets/chat_bottom_sheet.dart)
  * **Dòng code cụ thể (Dòng 160-189):**
    ```dart
    void _connectSocket() {
      socket = IO.io(
        _kBackendBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .build(),
      );
      socket!.connect();
      socket!.onConnect((_) {
        socket!.emit('joinProject', widget.projectId);
      });
      socket!.on('receiveMessage', (data) {
        _mergeMessages([data]);
      });
    }
    ```

### 4. Bảo (Frontend)
* **Table Calendar Integration:**
  * **File:** [calendar_screen.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/calendar/screens/calendar_screen.dart)
  * **Cách lấy danh sách sự kiện hiển thị trên lịch:**
    ```dart
    List<dynamic> _getEventsForDay(DateTime day) {
        return _events[DateTime(day.year, day.month, day.day)] ?? [];
    }
    ```
* **Pomodoro Timer Logic:**
  * **File:** [timer_screen.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/timer/screens/timer_screen.dart)
  * **Logic định dạng thời gian giây sang MM:SS:**
    ```dart
    String _formatDuration(int seconds) {
        final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
        final secs = (seconds % 60).toString().padLeft(2, '0');
        return '$minutes:$secs';
    }
    ```
* **Vẽ đồ thị Analytics UI:**
  * **File:** [analytics_screen.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/analytics/screens/analytics_screen.dart)
  * **Nội dung:** Xem cách truyền mảng dữ liệu `weeklyFocusTime` nhận từ API vào biểu đồ cột.

### 5. Đạt (Frontend - Phần dễ nhất)
* **Form Validation:**
  * **File:** [login_screen.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/auth/screens/login_screen.dart)
  * **Logic validate trường Email đơn giản:**
    ```dart
    validator: (value) {
      if (value == null || value.isEmpty) return 'Vui lòng nhập email';
      if (!value.contains('@')) return 'Email không hợp lệ';
      return null;
    }
    ```
* **Profile Settings (Update Username API call):**
  * **File:** [profile_screen.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/profile/screens/profile_screen.dart)
  * **API payload đổi tên người dùng:**
    ```dart
    final response = await http.put(
      Uri.parse('${AuthService.apiBaseUrl}/users/username'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'username': newUsernameController.text.trim()}),
    );
    ```
* **ListView.builder & notifications read status:**
  * **File:** [notifications_screen.dart](file:///c:/Users/user/Desktop/PRM/mobile/lib/features/notifications/screens/notifications_screen.dart)
  * **ListView hiển thị danh sách (Dòng UI):**
    ```dart
    ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final isRead = notif['isRead'] ?? false;
        return ListTile(
          title: Text(notif['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
          onTap: () => _markAsRead(notif['_id']),
        );
      }
    )
    ```
