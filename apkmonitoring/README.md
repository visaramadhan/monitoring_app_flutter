# APK Monitoring - PLTU Pacitan

Aplikasi monitoring work order untuk PLTU Pacitan yang dibangun dengan Flutter dan Firebase.

## 🚀 Fitur Utama

### 📋 Work Order Management
- **Tactical Work Order**: Manajemen PM, CM dengan kategori Common, Boiler, Turbin
- **Non-Tactical Work Order**: Manajemen PAM dengan kategori yang sama
- **Status Tracking**: Close, WShutt, WMatt, InProgress, Reschedule
- **Photo Upload**: Wajib upload foto untuk status Close
- **Excel Import/Export**: Import data dari Excel dan export hasil

### 📦 Inventory Management
- **Pengambilan Barang**: Tracking barang yang diambil
- **Permintaan Barang**: Manajemen permintaan barang
- **Excel Integration**: Import/export data inventory

### 👥 User Management (Admin/Supervisor)
- **Role-based Access**: Admin, Supervisor, Karyawan
- **Performance Monitoring**: Tracking kinerja karyawan
- **User Creation**: Buat akun karyawan baru
- **Password Reset**: Reset password via email

### 📊 Analytics & Reports
- **Performance Dashboard**: Pie charts dan bar charts
- **Historical Data**: Tracking data historis
- **Ranking System**: Peringkat kinerja karyawan
- **Real-time Sync**: Sinkronisasi real-time dengan Firebase

## 🛠️ Teknologi

- **Frontend**: Flutter 3.7+
- **Backend**: Firebase (Auth, Firestore)
- **State Management**: Provider pattern
- **Charts**: FL Chart
- **File Management**: Excel, File Picker
- **Image**: Image Picker dengan compression

## 📱 Instalasi & Setup

### 1. Prerequisites
```bash
# Install Flutter SDK
# Install Android Studio
# Install VS Code (optional)
```

### 2. Clone & Setup
```bash
git clone <repository-url>
cd apkmonitoring
flutter clean
flutter pub get
```

### 3. Firebase Configuration
1. Buat project Firebase baru
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Download `google-services.json` untuk Android
5. Download `GoogleService-Info.plist` untuk iOS
6. Update `firebase_options.dart`

### 4. Run Application
```bash
# Web
flutter run -d web

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## 🏗️ Struktur Project

```
lib/
├── models/           # Data models
│   ├── user_model.dart
│   └── work_order_model.dart
├── services/         # Business logic
│   ├── auth_service.dart
│   └── work_order_service.dart
├── screens/          # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── history_screen.dart
│   └── ...
├── widgets/          # Reusable widgets
│   ├── role_based_widget.dart
│   └── scrollable_data_table.dart
└── main.dart         # Entry point
```

## 👤 User Roles

### 🔴 Admin
- Full access ke semua fitur
- Manajemen user (create, delete, reset password)
- Monitoring kinerja semua karyawan
- Access ke semua work order dan inventory

### 🟡 Supervisor
- Monitoring kinerja karyawan
- Manajemen user terbatas
- Access ke work order dan inventory
- Tidak bisa delete admin

### 🟢 Karyawan
- Manajemen work order (tactical & non-tactical)
- Inventory management (pengambilan & permintaan)
- View history pribadi
- Update profile sendiri

## 📊 Performance Metrics

### Calculation Formula
```
Kinerja (%) = (Total Completed Tasks / Total Tasks) × 100

Where:
- Completed Tasks = Tasks with status "Close"
- Total Tasks = All assigned tasks (Tactical + Non-Tactical)
```

### Ranking System
- **🥇 Rank 1**: Highest performance percentage
- **🥈 Rank 2-3**: Top performers
- **📊 Others**: Ranked by performance descending

## 🔧 Configuration

### Firebase Rules (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null;
    }
    
    // Work orders
    match /tactical_work_orders/{docId} {
      allow read, write: if request.auth != null;
    }
    
    match /nontactical_work_order/{docId} {
      allow read, write: if request.auth != null;
    }
    
    // History
    match /work_order_history/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Firebase Auth Rules
- Email/Password authentication enabled
- Email verification disabled (for development)
- Password reset enabled

## 🚀 Deployment

### Android APK
```bash
flutter build apk --release
```

### Web
```bash
flutter build web --release
```

### iOS
```bash
flutter build ios --release
```

## 🐛 Troubleshooting

### Common Issues

1. **Gradle Build Failed**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Firebase Connection Issues**
   - Check `google-services.json` placement
   - Verify Firebase project configuration
   - Check internet connection

3. **Permission Issues (Android)**
   - Check `AndroidManifest.xml` permissions
   - Request runtime permissions for camera/storage

4. **Excel Import/Export Issues**
   - Check file format (xlsx/xls)
   - Verify file structure matches expected format
   - Check file permissions

## 📝 Data Structure

### Work Order
```dart
{
  'wo': 'WO-001',
  'desc': 'Description',
  'typeWO': 'PM/CM/PAM',
  'pic': 'Person in Charge',
  'status': 'Close/WShutt/WMatt/InProgress/Reschedule',
  'category': 'Common/Boiler/Turbin',
  'jenis_wo': 'Tactical/Non Tactical',
  'photo': true/false,
  'photoData': 'base64_string',
  'timestamp': 'ISO_date_string',
  'userId': 'firebase_user_id',
  'no': 1
}
```

### User
```dart
{
  'email': 'user@example.com',
  'username': 'username',
  'role': 'admin/supervisor/karyawan',
  'createdAt': 'timestamp'
}
```

## 🔄 Update & Maintenance

### Regular Tasks
1. **Database Cleanup**: Archive old completed work orders
2. **Performance Review**: Monthly performance analysis
3. **User Management**: Regular user access review
4. **Backup**: Regular Firebase backup
5. **Updates**: Keep dependencies updated

### Monitoring
- Firebase Console untuk database monitoring
- Firebase Analytics untuk usage tracking
- Performance monitoring via Firebase Performance

## 📞 Support

Untuk support dan pertanyaan:
- Email: support@pltu-pacitan.com
- Internal: IT Department PLTU Pacitan

---

**© 2025 PLTU Pacitan - APK Monitoring System**