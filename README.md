# 🧠 Pro-Level General Knowledge Quiz App

A feature-rich, high-performance mobile application built with **Flutter and Dart**. This app connects to the Open Trivia Database (OTDB) to provide real-time, dynamic quiz content across multiple categories and difficulty levels.

---

## 🚀 Technical Highlights

This project demonstrates a solid understanding of the Flutter ecosystem and core software engineering principles:

* **REST API Integration:** Uses the `http` package to fetch questions dynamically from an external JSON-based API.
* **Persistent Storage:** Implements `shared_preferences` to save and retrieve the user's high score locally on the device.
* **Complex State Management:** Utilizes an `enum` based `GameState` (Start, Loading, Playing, Results) to manage a seamless user experience.
* **Asynchronous Programming:** Features a 15-second countdown timer for each question using the `dart:async` library.
* **Advanced UI/UX:** * **Custom Theming:** A modern "Dark Mode" aesthetic using a custom `ThemeData` (Violet/Gray-900).
    * **Animated Transitions:** Uses `AnimatedSwitcher` for smooth screen changes.
    * **Responsive Layouts:** Employs `ConstrainedBox` to ensure the UI looks great on both mobile and large-screen tablets.



---

## 🛠 Tech Stack
* **Language:** Dart
* **Framework:** Flutter
* **Networking:** [http](https://pub.dev/packages/http)
* **Local Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences)
* **UI Architecture:** Material 3 with custom styling and Tailwind-inspired color palettes.

---

## 🌟 Key Features
* **Category & Difficulty Selection:** Choose from 11 categories (Computers, Science, Sports, etc.) and 3 difficulty levels.
* **Dynamic UI Feedback:** Answer buttons change color (Green/Red) instantly to show correctness.
* **High Score Tracking:** Your best performance is saved even after the app is closed.
* **Live Progress Bar:** A visual `LinearProgressIndicator` tracks your progress through the 10-question set.
* **Automatic HTML Decoding:** Custom utility methods to clean and display text containing HTML entities (like `&quot;` and `&#039;`).

---

## 📸 Screenshots
(start.jpg , second.jpg , third.jpg , end.jpg )

---

## ⚙️ How to Run Locally

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/0-Amit-0/quiz-app-flutter.git](https://github.com/0-Amit-0/quiz-app-flutter.git)
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the App:**
    ```bash
    flutter run
    ```

---
*Developed by **Amit Shakya** as a showcase of Full-Stack Mobile Development skills.*

