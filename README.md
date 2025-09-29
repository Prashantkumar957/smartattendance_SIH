# 📱 Smart Attendance App

Smart Attendance App is a comprehensive cross-platform mobile application built with **Flutter** that revolutionizes traditional attendance management in educational institutions.  

The app integrates **face verification** and **QR code scanning** to deliver a secure, automated attendance system that eliminates manual roll calls and paper-based tracking.  

<img width="736" height="560" alt="image" src="https://github.com/user-attachments/assets/b8da4490-dd86-4136-ae4f-181611da0a32" />

<img width="1418" height="622" alt="image" src="https://github.com/user-attachments/assets/08a8d273-0ce3-4cf0-8335-5d8ae393b79e" />



## 🚀 Features

### 🔐 Secure Attendance Marking
- Scan teacher-generated QR codes.  
- Validate presence with biometric face verification.  

### 📊 Real-Time Dashboard
- Present/absent counts.  
- Automatic attendance percentage calculation.  
- Weekly summaries & chronological activity history.  
- Beautiful **dark-themed UI** with smooth animations.  

### 🔄 Offline-to-Online Sync
- Stores attendance locally with **SharedPreferences**.  
- Automatically syncs with **cloud database** when online.  

### 🎉 Instant Feedback
- Animated success screens.  
- Dashboard increments values (+1 for each attendance).  

### 🧑‍🎓 Student Profile Management
- Name, Class, Section, Roll No. displayed in clean UI cards.  

---

## 🏗️ Architecture
- **Hybrid storage** → Cloud APIs + Local SharedPreferences.  
- **Flutter StatefulWidget with TickerProviderStateMixin** → Smooth animations.  
- **RESTful APIs** → Backend communication.  
- **Material Design 3** → Modern UI/UX.  

<img width="1418" height="622" alt="image" src="https://github.com/user-attachments/assets/193fb898-0f68-49d4-9e26-f1dfc34338a9" />


## 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)  
- **Backend:** RESTful APIs (JSON-based)  
- **Storage:** SharedPreferences (offline), Cloud database (online)  
- **Authentication:** Face Recognition, QR Code Scanning  
- **UI/UX:** Material Design 3, Dark Theme, Animated Widgets  

---

## 📸 Screenshots (Examples)
- QR Scan  
- Face Verification  
- Dashboard  
- Activity Feed  

---

## 📦 Installation

Clone the repository:
```bash
git clone https://github.com/your-username/smart-attendance-app.git
cd smart-attendance-app
