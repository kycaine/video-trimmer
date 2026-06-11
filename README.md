# KyStudio: The Ultimate Media Editor

A high-performance, open-source media editing application built with Flutter. **KyStudio** (formerly Ky-Cut) provides a suite of tools for processing video and audio files with ease, right from your device.

## 🚀 Features

KyStudio offers three main powerful tools:

1. **Video Trimmer**: 
   - Select and manage multiple segments from a single video file.
   - Frame-accurate trimming powered by FFmpeg.
   - Batch export all selected clips to your gallery.
2. **Video to Audio**: 
   - Convert video files directly into audio.
   - Support for multiple output formats: AAC (.m4a), MP3, WAV, and FLAC.
   - Native encoders for fast and reliable conversion.
3. **Audio Cutter**:
   - Trim and cut audio files (MP3, WAV, M4A, etc.).
   - Multi-clip support: cut multiple segments from one audio file.
   - Lightning-fast processing with precise duration cutting.

### Key Highlights:
- **High-Performance Preview**: Smooth video and audio playback using the `media_kit` engine.
- **Gallery Integration**: Automatically saves exported videos and audio to your device's library.
- **Modern UI/UX**: Clean, card-based interface with full support for Light and Dark modes.
- **Real-time Progress**: Visual feedback and background notifications during the export process.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Media Engine**: [Media Kit](https://media-kit.com)
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

KyStudio requires the following permissions to function correctly:
- **Videos/Photos/Audio**: To select input media and save exported clips.
- **Notifications**: To notify you when the export process is complete.
- **Storage**: For temporary file processing.

## 📖 Usage

### Video Trimmer & Audio Cutter
1. **Select Media**: Tap on the respective card to pick a video or audio file.
2. **Trim**: Use the range slider to select the start and end points of your clip.
3. **Add Clip**: Tap "Add Clip" to save the selection to your export list.
4. **Repeat**: Add as many clips as you want from the same file.
5. **Export**: Tap "Export All" to process and save all clips.

### Video to Audio
1. **Select Video**: Tap on the "Video to MP3" (Video to Audio) card to pick a video.
2. **Choose Format**: Select your desired output format (AAC, MP3, WAV, FLAC).
3. **Convert**: Tap the convert button and wait for the extraction to complete.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Developed with ❤️ by Kycaine*
