# 🚀 FlowMate Productivity System

> **A full-stack productivity & project management platform** built with **Flutter** (Mobile) and **Node.js/Express** (Backend), powered by **MongoDB Atlas** and deployed on **Vercel**.

FlowMate helps individuals and teams stay productive through task management, project collaboration, Pomodoro focus sessions, calendar scheduling, and real-time analytics — all wrapped in a premium Cyber Dark Mode UI.

---

## 📁 Project Structure

```
main/
├── be/                          # Backend (Node.js + Express)
│   ├── src/
│   │   ├── config/              # Database & Swagger configuration
│   │   ├── controllers/         # Business logic (auth, tasks, projects, etc.)
│   │   ├── middleware/          # JWT authentication middleware
│   │   ├── models/              # Mongoose schemas (User, Task, Project, etc.)
│   │   ├── routes/              # Express route definitions with Swagger docs
│   │   ├── utils/               # Utility functions
│   │   └── server.js            # App entry point, Socket.IO setup
│   ├── vercel.json              # Vercel deployment config
│   └── package.json
│
├── mobile/                      # Frontend (Flutter)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/       # App colors, sizes, durations, routes
│   │   │   └── widgets/         # Shared/reusable widgets
│   │   ├── features/            # Feature modules (feature-first architecture)
│   │   │   ├── analytics/       # Productivity reports & charts
│   │   │   ├── auth/            # Login, register, OTP verification
│   │   │   ├── calendar/        # Calendar & event scheduling
│   │   │   ├── dashboard/       # Dashboard overview
│   │   │   ├── focus/           # Pomodoro timer (Space Timer)
│   │   │   ├── notifications/   # In-app notifications
│   │   │   ├── profile/         # User profile management
│   │   │   ├── projects/        # Project & team collaboration
│   │   │   └── tasks/           # Task CRUD & filtering
│   │   ├── services/            # Auth, theme, locale, event-check services
│   │   └── main.dart            # App entry point
│   ├── assets/                  # Static assets (images, icons)
│   └── pubspec.yaml
│
├── system_specification.md      # Full system feature specification
└── study_plan.md                # Development study plan
```

---

## ⚙️ Prerequisites

| Tool | Version | Link |
|------|---------|------|
| **Node.js** | >= 18.x | [nodejs.org](https://nodejs.org/) |
| **Flutter SDK** | >= 3.0.0 | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **MongoDB Atlas** | Cloud | [mongodb.com](https://www.mongodb.com/atlas) |
| **Android Studio / Xcode** | Latest | For emulator/simulator |

---

## 🔧 Getting Started

### 1. Backend Setup

```bash
# Navigate to backend directory
cd be

# Install dependencies
npm install

# Create your .env file (see Environment Variables section below)

# Start development server (with hot-reload via nodemon)
npm run dev

# Or start production server
npm start
```

**Health Check:** [http://localhost:5000/api/health](http://localhost:5000/api/health)

**Swagger API Docs:** [http://localhost:5000/api-docs](http://localhost:5000/api-docs)

**Production API:** [https://prm-tan.vercel.app](https://prm-tan.vercel.app)

---

---

### 2. Mobile (Flutter) Setup

```bash
# Navigate to mobile directory
cd mobile

# Install Flutter dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

> **Note:** If running on an **Android Emulator**, the backend `localhost` will not be accessible directly. Replace `localhost` with `10.0.2.2` in your API base URL configuration inside the Flutter app.

---

## 🏗️ Technology Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Frontend** | Flutter (Dart) | Material 3, Provider state management, Dark/Light theme, Glassmorphism UI |
| **Backend** | Node.js + Express 5 | RESTful API, JWT auth, rate limiting, Swagger docs |
| **Database** | MongoDB Atlas | Cloud NoSQL via Mongoose ODM |
| **Real-time** | Socket.IO | Live project chat & real-time updates |
| **Email** | Nodemailer | OTP verification & notifications |
| **Deployment** | Vercel (Serverless) | Auto-deploy from Git |
| **API Docs** | Swagger UI (OpenAPI 3.0) | Interactive API documentation with custom dark theme |

---

## 📦 Dependencies

### Backend (`be/`)

| Package | Purpose |
|---------|---------|
| `express` | Web framework |
| `mongoose` | MongoDB ODM |
| `jsonwebtoken` | JWT authentication |
| `bcryptjs` | Password hashing |
| `cors` | Cross-origin resource sharing |
| `dotenv` | Environment variable management |
| `socket.io` | Real-time WebSocket communication |
| `nodemailer` | Email sending (OTP, notifications) |
| `express-rate-limit` | API rate limiting |
| `swagger-jsdoc` | Swagger spec generation |
| `swagger-ui-express` | Swagger UI hosting |
| `nodemon` *(dev)* | Hot-reload during development |
| `jest` *(dev)* | Testing framework |
| `supertest` *(dev)* | HTTP assertion testing |

### Mobile (`mobile/`)

| Package | Purpose |
|---------|---------|
| `http` | HTTP client for REST API calls |
| `provider` | State management |
| `shared_preferences` | Local storage (auth tokens, settings) |
| `socket_io_client` | Real-time Socket.IO client |
| `intl` | Date/time formatting & localization |
| `cupertino_icons` | iOS-style icons |

---

## 🧩 System Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Authentication & Profile** | Register, login (JWT), OTP verification, profile management |
| 2 | **Dashboard** | Productivity overview — pending/completed tasks, active projects, focus minutes, upcoming meetings |
| 3 | **Task Management** | Full CRUD with priority levels, due dates, labels, status filtering & search |
| 4 | **Project Management** | Create projects, invite members by email, assign tasks, auto-calculated KPI progress bar |
| 5 | **Calendar & Schedule** | Unified calendar aggregating meetings, reminders, and task deadlines |
| 6 | **Focus Sessions (Pomodoro)** | Space Timer with Focus/Short Break/Long Break/Custom modes, offline storage, session history |
| 7 | **Notifications** | System alerts for task deadlines, project invites, and meeting reminders |
| 8 | **Analytics & Reports** | Task completion rates, focus time charts by day/week/month |

---

## 🔌 API Routes

| Route Prefix | Description |
|--------------|-------------|
| `POST /api/auth/*` | Authentication (register, login, OTP) |
| `GET/PUT /api/users/*` | User profile & settings |
| `GET /api/dashboard/*` | Dashboard summary data |
| `CRUD /api/tasks/*` | Task management |
| `CRUD /api/projects/*` | Project management & members |
| `GET/POST/DELETE /api/calendar/*` | Calendar events |
| `POST /api/sessions` | Focus session recording |
| `GET/POST /api/focus-sessions` | Focus session management |
| `GET/PUT /api/notifications/*` | Notification management |
| `GET /api/analytics/*` | Productivity analytics |
| `GET /api/health` | Health check endpoint |

---

## 👥 User Roles

| Role | Permissions |
|------|-------------|
| **Member** | Manage personal tasks, join projects, use Pomodoro, view dashboard & calendar |
| **Project Leader** | All Member permissions + create projects, invite members, assign tasks, schedule meetings |
| **System Admin** | Database access (MongoDB Atlas), Vercel monitoring, Swagger API management |

---

## 🧪 Testing

```bash
# Backend unit tests
cd be
npm test
```

---

## 📝 Available Scripts

### Backend

| Script | Command | Description |
|--------|---------|-------------|
| Start | `npm start` | Run production server |
| Dev | `npm run dev` | Run with nodemon (hot-reload) |
| Test | `npm test` | Run Jest test suite |

### Mobile

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on device/emulator |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS app |

---

## 📄 Documentation

- [System Specification](system_specification.md) — Full feature requirements & role definitions
- [Study Plan](study_plan.md) — Development study plan & milestones
- [Swagger API Docs](https://prm-tan.vercel.app/api-docs) — Interactive API documentation

---

## 📜 License

ISC
