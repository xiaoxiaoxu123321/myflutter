# dimensional

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## API environment

Production builds use `https://www.myguanzhu.com` by default.

To run against the local Spring server:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.3.60:8080
```

To explicitly build with the production API:

```bash
flutter build ipa --dart-define=API_BASE_URL=https://www.myguanzhu.com
```
