📱 Smart Attendance App

Smart Attendance App is a comprehensive cross-platform mobile application built with Flutter that revolutionizes traditional attendance management in educational institutions.

The app integrates face verification and QR code scanning to deliver a secure, automated attendance system that eliminates manual roll calls and paper-based tracking.

🚀 Features

🔐 Secure Attendance Marking

Scan teacher-generated QR codes.

Validate presence with biometric face verification.

📊 Real-Time Dashboard

Present/absent counts.

Automatic attendance percentage calculation.

Weekly summaries & chronological activity history.

Beautiful dark-themed UI with smooth animations.

🔄 Offline-to-Online Sync

Stores attendance locally with SharedPreferences.

Automatically syncs with cloud database when online.

🎉 Instant Feedback

Animated success screens.

Dashboard increments values (+1 for each attendance).

🧑‍🎓 Student Profile Management

Name, Class, Section, Roll No. displayed in clean UI cards.

🏗️ Architecture

Hybrid storage → Cloud APIs + Local SharedPreferences.

Flutter StatefulWidget with TickerProviderStateMixin → Smooth animations.

RESTful APIs → Backend communication.

Material Design 3 → Modern UI/UX.

🛠️ Tech Stack

Frontend: Flutter (Dart)

Backend: RESTful APIs (JSON-based)

Storage: SharedPreferences (offline), Cloud database (online)

Authentication: Face Recognition, QR Code Scanning

UI/UX: Material Design 3, Dark Theme, Animated Widgets

📸 Screenshots (Examples)
QR Scan	Face Verification	Dashboard	Activity Feed

	
	
	
📦 Installation

Clone the repository:

git clone https://github.com/your-username/smart-attendance-app.git
cd smart-attendance-app


Get dependencies:

flutter pub get


Run the app:

flutter run

🎯 Why This Project?

✅ Eliminates proxy/false attendance.

✅ Saves administrative time.

✅ Provides real-time insights.

✅ Scalable for multiple institutions.

📌 Future Enhancements

📅 Teacher-side dashboard.

📍 GPS-based location verification.

🔔 Smart notifications for low attendance.

🧑‍🏫 Admin analytics portal.

📝 License

This project is licensed under the MIT License – free to use and modify.
