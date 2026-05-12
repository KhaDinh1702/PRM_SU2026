# PRM Project - Flutter & Node.js/MongoDB

Dự án này đã được thiết lập bởi Antigravity.

## Cấu trúc thư mục
- `be/`: Backend Node.js (Express, Mongoose).
- `mobile/`: Frontend Flutter.

## Hướng dẫn chạy

### 1. Backend
- Cần cài đặt [MongoDB](https://www.mongodb.com/try/download/community) và đang chạy tại `localhost:27017`.
- Di chuyển vào thư mục `be/`: `cd be`
- Cài đặt dependencies: `npm install` (đã chạy rồi)
- Chạy server: `npm start` hoặc `npm run dev` (sử dụng nodemon).
- Test API: [http://localhost:5000/api/health](http://localhost:5000/api/health)

### 2. Mobile (Flutter)
- Cần cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install/windows).
- Di chuyển vào thư mục `mobile/`: `cd mobile`
- Chạy lệnh: `flutter pub get` để tải dependencies.
- Chạy app: `flutter run`
- **Lưu ý:** Trong `lib/main.dart`, nếu chạy trên Android Emulator, hãy đổi `localhost` thành `10.0.2.2`.

## Các thư viện đã cài đặt
- **Backend:** `express`, `mongoose`, `dotenv`, `cors`.
- **Frontend:** `http`.
