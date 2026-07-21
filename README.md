# 💸 Expense Tracker Flutter App

A modern, highly responsive, and visually stunning expense tracking application built using **Flutter** and **Dart**. The application provides seamless local data persistence, custom expense categories, monthly budget planning with dynamic color-coded indicators, date range filtering, and optional transaction notes.

---

## 🚀 Key Features

*   **Smart Budget Tracking**: Define your monthly budget and keep track of your expenses in real time. Dynamic color-coded cards adjust visually depending on your remaining budget (green for safe, orange for warning, and red for over-budget).
*   **Intuitive Category Management**: Choose from popular pre-defined categories (Food, Transport, Shopping, Bills, Entertainment) or add your own custom categories on the fly.
*   **Robust Date Range Filters**: Quickly view and analyze your spending habits across multiple timelines:
    *   *All*
    *   *Today*
    *   *Yesterday*
    *   *This Month*
    *   *Last Month*
*   **Flexible Transaction Details**: Specify exact dates via a built-in calendar picker and add detailed transaction logs/notes.
*   **Modern Premium UI/UX**: Enjoy sleek gradient panels, clean typography, outline inputs, and intuitive action items designed for visual excellence.
*   **Robust Offline Persistence**: Built using **Hive**, a pure-Dart key-value database that works flawlessly across all platforms (Windows, Android, iOS, macOS, Web) with zero native compilation dependencies.

---

## 🛠️ Technology Stack & Architecture

- **UI Framework**: Flutter (Material 3 enabled)
- **Programming Language**: Dart
- **Local Database**: Hive & Hive Flutter (Pure Dart, No Native Toolchain Compilation Requirements)
- **Data Model**: Structured `Expense` objects mapped to and from JSON formats for reliable saving/loading.

### 💾 Storage Architecture Migration (SharedPreferences ➡️ Hive)

Originally, the project relied on `shared_preferences`, which requires native platform compiler bindings (Kotlin on Android, C++ on Windows). In constrained build environments (like Windows 11 with custom path layouts), Kotlin incremental compile caches would fail with Gradle-related file-lock errors.

We migrated the storage engine to **Hive**:
1.  **Zero Native Code**: Standardizes database reads/writes completely in Dart, bypassing native compilation.
2.  **Platform Agnostic**: Works out of the box on Windows, Android Emulator (`gphone16k`), and web builds.
3.  **Performant**: Written from the ground up for high speed and light memory footprint.

---

## ⚙️ Installation & How to Run

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.
- Android Studio / VS Code configured with Flutter plugins.

### Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/my_expense_app.git
    cd my_expense_app
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    - **Run on Connected Device/Emulator**:
      ```bash
      flutter run
      ```
    - **Run specifically on Windows**:
      ```bash
      flutter run -d windows
      ```
    - **Run specifically on Android Emulator**:
      ```bash
      flutter run -d emulator
      ```

---

## 📦 Project Structure

```
lib/
├── main.dart             # Application entry, UI layout, state management, and Hive persistence
pubspec.yaml              # App configuration and dependency management (Hive, Hive Flutter)
```

---

## 📄 License & Author

- **Author**: Ahmad Khan
- **License**: MIT License
