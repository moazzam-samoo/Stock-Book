# 📈 Stock Book

<p align="center">
  <img src="assets/icon/Stockk.png" width="150" alt="Stock Book Logo">
</p>

**Stock Book** is a premium, beautifully crafted, offline-first stock portfolio tracking application. Built with Flutter, it empowers investors to track their portfolio value, visualize asset allocation, and set target selling prices with an elegant and fast user experience.

---

## ✨ Features

- **📊 Comprehensive Dashboard**
  - Track **Total Portfolio Value**, **Starting Capital**, **Currently Invested**, **Free Cash**, and **Realized Profit/Loss**.
  - Interactive portfolio distribution charts and detailed asset breakdown.
- **💼 Offline-First Architecture**
  - Add, edit, and manage stock transactions seamlessly even without an internet connection.
  - Powered by **Hive** for instant local data persistence and **Firebase Firestore** for background cloud synchronization.
- **🎯 Target Price Tracking**
  - Set an optional Target Selling Price for your lots.
  - Automatically calculates and displays the estimated profit percentage (+%) to help you stick to your investment strategy.
- **🎨 Premium UI/UX**
  - Gorgeous **Dark Theme** utilizing deep navy backgrounds and glassmorphism.
  - **Outfit** Google Font for sleek, modern typography.
  - Stunning animated **Splash Screen** with gradient text and seamless transitions.
- **📱 Adaptive Launcher Icons**
  - Fully optimized for Android and iOS with crisp, adaptive white backgrounds for perfect system launcher blending.

## 🛠 Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (`riverpod_annotation`, `hooks_riverpod`)
- **Architecture**: **Domain-Driven Design (DDD)** & **Clean Architecture** principles
  - `lib/domain`: Entities, Core Business Logic, and Calculators
  - `lib/data`: Models, Repositories, Hive Data Sources, and Firebase syncing
  - `lib/presentation`: Screens, Widgets, and Riverpod Controllers
- **Local Database**: [Hive](https://pub.dev/packages/hive) (TypeAdapters for complex entities)
- **Cloud Database**: [Firebase Cloud Firestore](https://firebase.google.com/docs/firestore)
- **Authentication**: [Firebase Auth](https://firebase.google.com/docs/auth) (Anonymous Login for friction-free onboarding)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Animations & Visuals**: `flutter_animate`, `fl_chart`, `google_fonts`

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version ^3.12.0 or higher)
- Dart SDK
- IDE (VS Code, Android Studio, etc.)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/stock_investment_tracker.git
   cd stock_investment_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (for Riverpod, Freezed, and JSON Serializable)**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📸 Screenshots

*(Replace with actual GitHub hosted image links when uploading to your repository)*

| Dashboard | Add Transaction | Lot Details |
| --- | --- | --- |
| `<img src="path/to/dashboard_screenshot.png" width="250">` | `<img src="path/to/add_screenshot.png" width="250">` | `<img src="path/to/details_screenshot.png" width="250">` |

## 🏗 Project Structure

```text
lib/
├── core/               # Theme, constants, formatting utilities, enums
├── data/               # API clients, DTOs (Models), Hive Adapters, Repositories
├── domain/             # Entities, Use Cases, Core Portfolio Calculators
├── presentation/       # UI layer (Screens, Widgets, Providers)
│   ├── auth/           # Sign-In / Onboarding screens
│   ├── dashboard/      # Main portfolio dashboard
│   ├── splash/         # Animated Splash screen
│   ├── transactions/   # Add/Edit lot flows and list views
│   └── routing/        # GoRouter configuration
└── main.dart           # App entry point
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🛡 License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Powered by Coding District*
