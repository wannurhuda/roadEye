# 🛣️ roadEye

**KitaHack 2026 Project** — AI-Powered Pothole & Road Damage Reporter

## What is roadEye?

roadEye helps drivers report potholes and road damage using their phone camera. Our AI (Google Gemini) analyzes the photo and determines severity. Reports appear on a live map so everyone can avoid dangerous roads.

## Tech Stack

- **Frontend**: Flutter (Android & iOS)
- **AI**: Google Gemini API (image analysis & severity classification)
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Maps**: Google Maps API
- **Notifications**: Firebase Cloud Messaging (FCM)

## SDG Alignment

**SDG 11: Sustainable Cities & Communities**

Road damage causes accidents, vehicle repairs, and traffic delays. roadEye gives city councils real-time visibility and helps drivers avoid hazards.

## Setup Instructions

### Prerequisites

- Flutter SDK (3.16 or higher)
- Android Studio with Flutter plugin
- Firebase account
- Google Cloud account (for Maps API)

### Installation

1. Clone this repo:
```
   git clone https://github.com/yourusername/pothoalert.git
   cd pothoalert
```

2. Install dependencies:
```
   flutter pub get
```

3. Add your `google-services.json` to `android/app/`

4. Add your Google Maps API key to `android/app/src/main/AndroidManifest.xml`

5. Run the app:
```
   flutter run
```

## Current Status (Week 1)

✅ Flutter project setup  
✅ Firebase configured  
✅ Google Maps integrated  
✅ Image picker working  
⏳ Gemini AI integration (Week 2)  
⏳ Firestore database save (Week 2)  
⏳ Real-time map pins (Week 3)

## Team

- [Your Name] — [Your University] — GDGoC Member
- [Team Member 2]
- [Team Member 3]

## License

