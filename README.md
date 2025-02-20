#  Attendance Management System

## Overview
A Flutter-based mobile application for managing student attendance and leave requests. The application helps students track their attendance across different classes, view their attendance statistics, and manage leave requests.

## Features
- **Attendance Dashboard**
  - Real-time attendance percentage calculation
  - Visual representation of present, absent, and approved leaves
  - Class-wise attendance breakdown

- **Leave Management**
  - Submit leave requests
  - Track approved leaves
  - View leave request status

- **Class Schedule**
  - View daily class schedule
  - Check class details and instructor information
  - Track attendance for individual classes

- **Real-time Updates**
  - Live attendance tracking
  - Instant leave request status updates
  - Dynamic class schedule updates

## Technical Stack
- **Frontend**: Flutter/Dart
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore

## Database Structure

### Collections
1. **users**
   - User profile information
   - Fields: username, role, etc.

2. **attendance**
   - Attendance records
   - Fields: studentId, classId, date, status (P/A), subject, teacherId

3. **classes**
   - Class information
   - Fields: subjectName, teacherId, schedule

4. **leave_requests**
   - Leave application records
   - Fields: studentId, status (approved/pending/rejected), date

## Setup Instructions

1. **Prerequisites**
   - Flutter SDK
   - Firebase account
   - Android Studio/VS Code

2. **Installation**
   ```bash
   # Clone the repository
   git clone [repository-url]

   # Navigate to project directory
   cd student-attendance-system

   # Install dependencies
   flutter pub get

   # Run the app
   flutter run
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Add Android/iOS apps in Firebase console
   - Download and add google-services.json/GoogleService-Info.plist
   - Enable Authentication and Firestore

## Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: [version]
  firebase_auth: [version]
  cloud_firestore: [version]
  google_fonts: [version]
```

## Screens and Components

### RecordsScreen
- Main dashboard showing attendance statistics
- Features:
  - Attendance percentages
  - Quick action buttons
  - Class-wise attendance cards
  - Approved leave count

### MessageScreen
- Leave request submission interface
- Features:
  - Leave application form
  - Request status tracking

### StudentScheduleScreen
- Daily class schedule view
- Features:
  - Class timings
  - Subject details
  - Instructor information

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Support
For support and queries, please contact [aayushmanbajracharya5@gmail.com]

