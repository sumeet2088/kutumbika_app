# Kutumbika Flutter App

A Flutter application for Kutumbika - "Everything Your Family Needs. One Secure Place."

## Features Implemented

### ✅ Completed Screens
1. **Splash Screen** - App initialization with logo and loading indicator
2. **Login Screen** - Mobile number input, OTP option, social login buttons
3. **OTP Verification Screen** - 6-digit OTP input with resend timer
4. **Create Family Screen** - Family name input with skip option
5. **Home Screen** - Dashboard with categories and bottom navigation

### ✅ API Integration
- **App Initialization** - Calls `/api/v1/app/init` endpoint on startup
- **OTP Service** - Send and verify OTP via `/api/v1/auth/otp/send` and `/api/v1/auth/otp/verify`
- **User Service** - Get user details via `/api/v1/user/details`
- **Document Service** - Get documents via `/api/v1/documents`

### ✅ Design System
- **Color Palette** - Extracted from logo:
  - Primary Dark Blue: `#0D1B2A`
  - Secondary Blue: `#1B3A6D`
  - Gold/Yellow: `#D4AF37`
  - Grey: `#687280`
  - Light Grey: `#F2F4F7`
- **Typography**:
  - Headings: Playfair Display Bold
  - Body: Inter Regular

## Project Structure

```
kutumbika_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/               # Screen widgets
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── otp_verification_screen.dart
│   │   ├── create_family_screen.dart
│   │   └── home_screen.dart
│   ├── services/              # API services
│   │   └── api_service.dart
│   ├── widgets/               # Reusable widgets
│   │   ├── bottom_navigation.dart
│   │   └── category_card.dart
│   └── utils/                 # Utilities
│       └── app_colors.dart
├── assets/
│   ├── images/                # App images
│   └── logo/                  # Logo assets
└── pubspec.yaml               # Dependencies
```

## Setup Instructions

### Prerequisites
1. Install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Ensure you have Android Studio/VS Code with Flutter extension
3. Configure Android/iOS development environment

### Installation
1. Navigate to the project directory:
   ```bash
   cd kutumbika_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Configuration
- Update API Gateway URL in `lib/services/api_service.dart`:
  ```dart
  static const String baseUrl = 'http://localhost:8080'; // Change to your API Gateway URL
  ```

### Logo Integration
1. Add your logo files to `assets/logo/` directory
2. Update `pubspec.yaml` to include your logo files
3. Replace the placeholder logo in `splash_screen.dart` with actual logo image

## API Endpoints Used

### Public Side (via API Gateway)
- `POST /api/v1/app/init` - App initialization
- `POST /api/v1/auth/otp/send` - Send OTP
- `POST /api/v1/auth/otp/verify` - Verify OTP
- `GET /api/v1/user/details` - Get user details
- `GET /api/v1/documents` - Get documents list

## Development Notes

### First Launch Flow
1. Splash Screen calls `/api/v1/app/init` with device info
2. Returns visitor token and device reference number
3. Navigates to Login Screen
4. User enters mobile number and sends OTP
5. User verifies OTP and gets user token
6. Navigates to Home Screen (optionally via Create Family Screen)

### Color Theme
- The app uses the official Kutumbika color palette extracted from the logo
- Primary actions use dark blue (#0D1B2A)
- Accent elements use gold (#D4AF37)
- Backgrounds use light grey (#F2F4F7)
- Text uses grey (#687280) for secondary information

### Next Steps
1. Add actual logo images to assets/logo/
2. Implement remaining screens from wireframes
3. Add document upload functionality
4. Implement family management features
5. Add reminder functionality
6. Implement profile and settings screens
7. Add proper error handling and loading states
8. Implement secure storage for tokens
9. Add proper navigation and state management
10. Implement document viewing and download

## Testing
- Ensure API Gateway is running on `http://localhost:8080`
- Test OTP flow with valid mobile numbers
- Verify token storage and authentication
- Test document listing and retrieval
