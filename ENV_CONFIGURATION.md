# Environment Configuration

This Flutter app uses environment variables for configuration management using the `flutter_dotenv` package.

## Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Create your environment file:**
   Copy the example file:
   ```bash
   cp .env.example .env
   ```

3. **Configure your environment variables:**
   Edit the `.env` file with your specific configuration values.

## Environment Variables

### API Configuration
- `API_BASE_URL`: The base URL for your API Gateway (default: `http://localhost:8080`)
- `API_VERSION`: API version (default: `v1`)
- `API_TIMEOUT`: API request timeout in seconds (default: `30`)

### App Configuration
- `APP_NAME`: Application name (default: `Kutumbika`)
- `APP_VERSION`: Current app version (default: `1.0.0`)
- `BUILD_NUMBER`: Build number (default: `1`)

### Locale Configuration
- `DEFAULT_LOCALE`: Default locale (default: `en-IN`)
- `DEFAULT_TIMEZONE`: Default timezone (default: `Asia/Kolkata`)

### OTP Configuration
- `OTP_LENGTH`: Number of digits in OTP (default: `6`)
- `OTP_RESEND_TIMER`: OTP resend timer in seconds (default: `30`)
- `MOBILE_NUMBER_LENGTH`: Expected mobile number length (default: `10`)

### Feature Flags
- `ENABLE_ANALYTICS`: Enable analytics tracking (default: `false`)
- `ENABLE_CRASH_REPORTING`: Enable crash reporting (default: `false`)
- `ENABLE_LOGGING`: Enable debug logging (default: `true`)

### Storage Configuration
- `SECURE_STORAGE_ENABLED`: Enable secure storage for sensitive data (default: `true`)
- `SHARED_PREFERENCES_ENABLED`: Enable shared preferences (default: `true`)

## Usage in Code

The app uses the `EnvService` singleton to access environment variables:

```dart
import '../services/env_service.dart';

// Get API base URL
String baseUrl = EnvService.instance.apiBaseUrl;

// Check feature flags
if (EnvService.instance.enableLogging) {
  print('Debug message');
}
```

For convenience, you can also use `AppConstants`:

```dart
import '../utils/app_constants.dart';

// Get API base URL
String baseUrl = AppConstants.baseUrl;

// Check feature flags
if (AppConstants.enableLogging) {
  print('Debug message');
}
```

## Environment Files

- `.env`: Your local environment configuration (not committed to git)
- `.env.example`: Example configuration file (committed to git)
- `.env.production`: Production environment (optional)
- `.env.development`: Development environment (optional)

## Security

⚠️ **Important**: Never commit `.env` files containing sensitive information to version control. The `.gitignore` file is configured to ignore `.env` files.

## Different Environments

You can create different environment files for different stages:

1. **Development**: `.env.development`
2. **Staging**: `.env.staging`
3. **Production**: `.env.production`

To load a specific environment file, modify the `EnvService.initialize()` method:

```dart
await dotenv.load(fileName: '.env.production');
```

## Default Values

The app includes sensible default values for all configuration variables, so it will work even without a `.env` file. However, you should create a `.env` file for your specific configuration needs.

## Troubleshooting

If environment variables are not loading:
1. Ensure `.env` file exists in the project root
2. Check that the file name is exactly `.env` (not `.env.txt` or similar)
3. Verify the file format (KEY=VALUE, one per line)
4. Restart the app after making changes to `.env`
