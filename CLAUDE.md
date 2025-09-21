# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

**Dependencies and setup:**
```bash
flutter pub get              # Install dependencies
```

**Development:**
```bash
flutter run                  # Run the app (default device)
flutter run -d windows       # Run on Windows
flutter run -d android       # Run on Android emulator
flutter run -d ios          # Run on iOS simulator
```

**Code quality:**
```bash
flutter analyze             # Static analysis using analysis_options.yaml
flutter test                # Run unit tests
```

**Build:**
```bash
flutter build apk           # Build Android APK
flutter build windows       # Build Windows executable
flutter build ios           # Build iOS app
```

## Project Architecture

This is a simple Flutter bookkeeping/accounting application with the following structure:

**Core Components:**
- `lib/main.dart` - Main entry point containing:
  - `BookkeepingApp` - Root MaterialApp with indigo theme
  - `TransactionPage` - Main screen with transaction list and balance display
  - Transaction management UI including add/delete functionality
- `lib/transaction.dart` - Data model for financial transactions with JSON serialization

**Key Architecture Patterns:**
- Single-page app with StatefulWidget for state management
- Local persistence using SharedPreferences for transaction storage
- JSON serialization for data persistence
- Material Design UI with custom theme and card-based layout

**Data Flow:**
- Transactions stored as JSON strings in SharedPreferences
- Balance calculated dynamically from transaction list
- UI updates through setState() when transactions are added/removed
- Optimistic updates with undo functionality for deletions

**UI Features:**
- Chinese language interface (记账本 = Bookkeeping)
- Dismissible list items for deletion with undo
- Modal dialog for adding transactions
- Balance card showing current total
- Income/expense toggle with color coding (green/red)

**Dependencies:**
- `intl: ^0.19.0` - Date formatting
- `shared_preferences: ^2.2.3` - Local data persistence
- `flutter_lints: ^2.0.0` - Code linting rules

## Development Notes

- The app description in pubspec.yaml says "bookkeeping application" but README mentions "calculator demo" - the actual implementation is a bookkeeping app
- Uses Material Design with indigo primary color scheme
- Transaction IDs are generated using current timestamp as string
- All monetary amounts are displayed with 2 decimal places
- Date formatting uses locale-aware formatting via intl package