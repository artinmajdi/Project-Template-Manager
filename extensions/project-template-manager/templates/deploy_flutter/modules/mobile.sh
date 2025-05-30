#!/bin/bash

# ====================================================================
# MOBILE (iOS AND ANDROID) BUILD FUNCTIONS
# ====================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to build for iOS
build_ios() {
  local build_args="$1"
  local app_dir="$2"
  local flavor="$3"

  print_info "Building iOS application..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    exit_with_error "iOS builds can only be performed on macOS."
  fi

  # Check if Xcode is installed
  if ! command_exists xcodebuild; then
    exit_with_error "Xcode is not installed.\nPlease install Xcode from the App Store."
  fi

  # Build iOS app with flavor if specified
  if [[ -n "$flavor" ]]; then
    print_info "Building with flavor: $flavor"
    flutter build ios --release --flavor "$flavor" $build_args
  else
    flutter build ios --release $build_args
  fi

  if [ $? -ne 0 ]; then
    exit_with_error "iOS build failed."
  fi

  print_success "iOS build successful!"
  print_warning "To deploy to the App Store, open Xcode and use the Archive feature:"
  echo "1. Open the iOS project in Xcode: open ios/Runner.xcworkspace"
  echo "2. Select Product > Archive"
  echo "3. Once archiving is complete, click 'Distribute App'"
}

# Function to build for Android
build_android() {
  local build_type="$1"
  local app_dir="$2"
  local flavor="$3"
  local build_args="$4"

  print_info "Building Android application..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Use the provided build type or ask for build type
  if [ -z "$build_type" ]; then
    build_type=$(ask_user_choice "Which Android build type would you like?" "1) APK (for direct installation)\n2) App Bundle (for Play Store)" "1")
  fi

  # Build with flavor if specified
  local flavor_arg=""
  if [[ -n "$flavor" ]]; then
    print_info "Building with flavor: $flavor"
    flavor_arg="--flavor $flavor"
  fi

  if [ "$build_type" = "1" ]; then
    flutter build apk --release $flavor_arg $build_args

    if [ $? -ne 0 ]; then
      exit_with_error "Android APK build failed."
    fi

    print_success "Android APK build successful!"
    print_warning "The APK file is located at:"

    if [[ -n "$flavor" ]]; then
      echo "build/app/outputs/flutter-apk/$flavor/release/app-$flavor-release.apk"
    else
      echo "build/app/outputs/flutter-apk/app-release.apk"
    fi

  elif [ "$build_type" = "2" ]; then
    flutter build appbundle --release $flavor_arg $build_args

    if [ $? -ne 0 ]; then
      exit_with_error "Android App Bundle build failed."
    fi

    print_success "Android App Bundle build successful!"
    print_warning "The App Bundle is located at:"

    if [[ -n "$flavor" ]]; then
      echo "build/app/outputs/bundle/$flavor/release/app-$flavor-release.aab"
    else
      echo "build/app/outputs/bundle/release/app-release.aab"
    fi

    print_warning "Upload this file to the Google Play Console to publish your app."

  else
    print_error "Invalid choice. Building APK."
    flutter build apk --release $flavor_arg $build_args

    if [ $? -ne 0 ]; then
      exit_with_error "Android APK build failed."
    fi

    print_success "Android APK build successful!"
    print_warning "The APK file is located at:"

    if [[ -n "$flavor" ]]; then
      echo "build/app/outputs/flutter-apk/$flavor/release/app-$flavor-release.apk"
    else
      echo "build/app/outputs/flutter-apk/app-release.apk"
    fi
  fi
}

# Function to install APK on connected device
install_android_apk() {
  local app_dir="$1"
  local flavor="$2"

  print_info "Installing APK on connected device..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Check if adb is available
  if ! command_exists adb; then
    exit_with_error "Android Debug Bridge (adb) not found. Please install Android SDK platform tools."
  fi

  # Check if any device is connected
  if [[ -z "$(adb devices | grep -v 'List' | grep 'device')" ]]; then
    exit_with_error "No Android device connected. Please connect a device and enable USB debugging."
  fi

  # Determine APK path based on flavor
  local apk_path
  if [[ -n "$flavor" ]]; then
    apk_path="build/app/outputs/flutter-apk/$flavor/release/app-$flavor-release.apk"
  else
    apk_path="build/app/outputs/flutter-apk/app-release.apk"
  fi

  # Check if APK exists
  if [ ! -f "$apk_path" ]; then
    exit_with_error "APK not found at $apk_path. Please build the app first."
  fi

  # Install APK
  print_info "Installing $apk_path..."
  adb install -r "$apk_path"

  if [ $? -ne 0 ]; then
    exit_with_error "Failed to install APK."
  fi

  print_success "APK installed successfully!"
}

# Function to open iOS project in Xcode
open_ios_project() {
  local app_dir="$1"

  print_info "Opening iOS project in Xcode..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    exit_with_error "This function can only be used on macOS."
  fi

  # Check if Xcode is installed
  if ! command_exists xcodebuild; then
    exit_with_error "Xcode is not installed. Please install Xcode from the App Store."
  fi

  # Check if iOS directory exists
  if [ ! -d "ios" ]; then
    exit_with_error "iOS directory not found. Make sure you're in a Flutter project with iOS support."
  fi

  # Open project in Xcode
  print_info "Opening ios/Runner.xcworkspace..."
  open ios/Runner.xcworkspace

  if [ $? -ne 0 ]; then
    # Try opening xcodeproj if xcworkspace doesn't exist
    print_warning "xcworkspace not found, trying xcodeproj..."
    open ios/Runner.xcodeproj

    if [ $? -ne 0 ]; then
      exit_with_error "Failed to open iOS project."
    fi
  fi

  print_success "iOS project opened in Xcode!"
}
