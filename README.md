# 🌍 Bambare Travel Management System (TMS)

> ⚠️ **This project is currently ongoing** — features and documentation are actively being developed.

This is a cross-platform mobile **Travel Management System** designed for **Bambare Travels**, a Sri Lankan tourism service provider. The system is built to digitize and automate tourism operations — replacing manual, paper-based workflows with a modern mobile-first platform that supports tour bookings, map navigation, expense tracking, and admin reporting.

---

## 🚀 Project Overview

The system offers a **RESTful API backend** and a **Flutter-based mobile frontend** for both Android and iOS platforms. It allows customers to browse and book tour packages, track travel expenses, and navigate destinations — while giving administrators full control over users, tours, hotels, and system-wide reporting via a real-time dashboard.

---

## 🛠️ Technologies Used

### ✅ Frontend
- **Flutter 3.x (Dart):** Cross-platform mobile UI for Android 8.0+ and iOS 12.0+
- **Firebase Authentication:** Secure login, registration, email verification, and session management
- **Firebase Firestore Real-time Listeners:** Live data sync for booking status and notifications
- **Google Maps SDK:** Interactive maps, location pinning, and turn-by-turn navigation
- **fl_chart:** Data visualization for expense reports and admin dashboards

### ✅ Backend
- **Node.js 18 LTS + Express.js 4.x:** RESTful API server and routing
- **Firebase Firestore:** Real-time NoSQL database for users, bookings, and expenses
- **MongoDB Atlas 6.0+:** Structured relational storage for tour packages, itineraries, hotels, and vehicles (3NF normalized, ACID transactions)
- **Google Cloud Storage:** Media and file storage for tour images and PDF reports
- **REST API:** Standard endpoints covering all modules (GET, POST, PUT, DELETE)
- **JWT + bcrypt:** Secure token-based auth and password hashing

### ✅ External Integrations
- **Google Maps Platform:** Maps SDK, Places API, Directions API
- **ExchangeRate-API v6:** Real-time currency conversion with 4-hour cache
- **SendGrid:** SMTP transactional email for booking confirmations and password resets
- **Twilio:** SMS notifications for booking confirmations and OTP delivery
- **Firebase Cloud Messaging (FCM):** Push notifications to Android and iOS devices
- **Google Cloud Platform (GCP):** Auto-scaling hosting with 4 vCPUs, 16GB RAM, 99.5% uptime SLA

---

## 🔗 Features

- **User Management & Authentication** — Register, login, profile CRUD, role-based access (Admin / Customer), account lockout after 5 failed attempts
- **Tour Package Browsing & Booking** — Browse, filter, and book tours with real-time availability, booking history, and cancellation support
- **Map Navigation & Places Recommendation** — Interactive Google Maps with recommended places, category filters, and turn-by-turn directions
- **Expense Tracking & Currency Converter** — Log travel expenses by category, convert currencies in real-time, and generate monthly expense reports
- **Admin Dashboard & Reporting** — Real-time KPIs, full CRUD for tours/hotels/users, push notification broadcasting, and PDF/CSV report exports
- **Notifications** — Automated email, SMS, and push notifications for all key booking events
- **Offline Support** — Cached data viewing and currency rate fallback when offline

---

## 👥 Team & Module Distribution

| # | Name | Reg. No. | Module |
|---|---|---|---|
| 1 | Avishka Bambaradeniya | SA24100931 | FR3 — Map, Navigation & Places Recommendation |
| 2 | Prarthana Meegahakumbura | SA24101440 | FR4 — Expense Tracking & Currency Converter |
| 3 | Shamla Noufer | SA24610780 | FR2 — Tour & Activity Planning and Booking |
| 4 | P. Vidhuja | SA24101945 | FR1 — User Management & Authentication |
| 5 | Oshidi Yapa | SA24610566 | FR5 — Admin Panel, Notifications & Reporting |

---

## 📁 Folder Structure

```
bambare-tms/
  ├── mobile/                        # Flutter mobile application
  │   ├── lib/
  │   │   ├── main.dart
  │   │   ├── screens/
  │   │   │   ├── auth/              # FR1 - Login, Register, Profile
  │   │   │   ├── tours/             # FR2 - Tour listing, booking flow
  │   │   │   ├── maps/              # FR3 - Map, navigation, places
  │   │   │   ├── expenses/          # FR4 - Expense tracker, currency
  │   │   │   └── admin/             # FR5 - Admin dashboard, reports
  │   │   ├── models/
  │   │   ├── services/
  │   │   └── widgets/
  │   └── pubspec.yaml
  ├── backend/                       # Node.js + Express REST API
  │   ├── server.js
  │   ├── config/
  │   ├── controllers/
  │   ├── models/
  │   │   ├── User.js
  │   │   ├── Booking.js
  │   │   ├── TourPackage.js
  │   │   ├── Expense.js
  │   │   └── Notification.js
  │   ├── routes/
  │   ├── middleware/
  │   ├── package.json
  │   └── package-lock.json
  ├── docs/                          # Project documentation & diagrams
  │   ├── SRS_report.pdf
  │   ├── Architecture_diagram.png
  │   ├── ER_diagram.png
  │   ├── Class_diagram.png
  │   ├── Usecase_diagram.png
  │   ├── DFD_Level0.png
  │   └── DFD_Level1.png
  └── README.md
```

---

## 📦 Getting Started

**Clone the repository:**
```bash
git clone https://github.com/your-org/bambare-tms.git
cd bambare-tms
```

**Backend setup:**
```bash
cd backend
npm install
cp .env.example .env
# Fill in your Firebase, MongoDB, Maps, and notification credentials
node server.js
```

**Flutter app setup:**
```bash
cd mobile
flutter pub get
flutter run
```

The backend API will be available at `http://localhost:3000` (or your configured port).

---

## 🔐 Environment Variables

Create a `.env` file inside `/backend` based on the following:

```env
PORT=3000
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/bambare
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
EXCHANGE_RATE_API_KEY=your-exchangerate-api-key
SENDGRID_API_KEY=your-sendgrid-api-key
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
JWT_SECRET=your-jwt-secret
JWT_EXPIRY=24h
```

> ⚠️ Never commit `.env` to version control. It is included in `.gitignore`.

---

## 📝 License

This project is developed for academic and client purposes — **Bambare Travels, Sri Lanka**.  
Group TMS — G01 | SLIT City University (SCU)
