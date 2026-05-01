# Ky-Cut: Pro Video Trimmer

A high-performance, open-source video trimming application built with Flutter. **Ky-Cut** allows users to pick videos, select multiple segments (clips) with frame-accurate precision, and export them directly to their gallery.

## 🚀 Features

- **Multi-Clip Trimming**: Select and manage multiple segments from a single video file.
- **Precise Export**: Powered by FFmpeg for frame-accurate video processing.
- **High-Performance Preview**: Smooth video playback using the `media_kit` engine.
- **Batch Processing**: Export all selected clips in one go with real-time progress tracking.
- **Gallery Integration**: Automatically saves exported videos to your device's photo library/gallery.
- **Modern UI/UX**: Clean interface with full support for Light and Dark modes.
- **Real-time Progress**: Visual feedback during the export process.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Video Engine**: [Media Kit](https://media-kit.com)
- **Processing Engine**: [FFmpeg Kit](https://github.com/ffmpeg_kit/ffmpeg-kit)
- **File Handling**: File Picker & Path Provider
- **Storage**: Gal (Gallery Access Layer)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (>= 3.7.0)
- Android Studio / VS Code
- Android SDK (for Android build) / Xcode (for iOS build)

## ⚙️ Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kycaine/video-trimmer.git
   cd video-trimmer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Platform-specific setup**

   ### Android
   Ensure your `minSdkVersion` is at least **21** in `android/app/build.gradle`.

   ### iOS
   Add the following keys to your `Info.plist` for permissions:
   - `NSPhotoLibraryUsageDescription`
   - `NSPhotoLibraryAddUsageDescription`

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Permissions

Ky-Cut requires the following permissions to function correctly:
- **Videos/Photos**: To select input videos and save exported clips.
- **Notifications**: To notify you when the export process is complete.
- **Storage**: For temporary file processing.

## 📖 Usage

1. **Pick a Video**: Tap on "Select a Video" from the home screen.
2. **Trim**: Use the range slider to select the start and end points of your clip.
3. **Add Clip**: Tap "Add Clip" to save the selection to your export list.
4. **Repeat**: You can add as many clips as you want from the same video.
5. **Export**: Tap "Export All" to process and save all clips to your gallery.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Developed with ❤️ by Kycaine*
