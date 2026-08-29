# Smart X - Ethiopian High School Learning App 🇪🇹

Smart X is an offline-first Flutter mobile application designed for Ethiopian high school students (Grades 9–12), offering interactive quizzes, chapter-by-chapter summaries, formula cheat sheets, and Telegram community integration aligned with the Ethiopian National Educational curriculum (NEAEA).

## 🚀 Features

- **Grades 9–12 Curriculum**: Comprehensive coverage of Mathematics, Biology, Physics, Chemistry, English, History, Geography, Civics, Economics, and Agriculture.
- **Interactive Quizzes**: Instant answer validation, detailed Amharic & English explanations, and score breakdowns.
- **High-Yield Short Notes**: Chapter summary notes, essential formulas, and trap-avoidance exam tips.
- **Offline Mode**: Study anytime without internet connection.
- **Bilingual**: Seamless switching between English and Amharic (አማርኛ).
- **Telegram Community**: Direct link to the Smart X student channel (`@smartx_ethiopia`).
- **CI/CD Pipeline**: GitHub Actions workflow (`.github/workflows/build.yml`) for automated testing, linting, asset optimization, APK generation with ABI splitting (`arm64-v8a`, `armeabi-v7a`, `x86_64`), and automated GitHub Releases.

## 🛠️ Build and Run

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run the app
flutter run

# Build release APK
flutter build apk --release --split-per-abi
```

## 📦 CI/CD Workflow

The GitHub Actions workflow in `.github/workflows/build.yml` automatically:
1. Validates Dart code and runs tests.
2. Optimizes all images with `optipng` and `jpegoptim`.
3. Injects signing keystores securely from GitHub Secrets.
4. Generates split-per-ABI production release APKs.
5. Publishes an automated GitHub Release with download assets.
