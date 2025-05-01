#!/bin/bash

# ====================================================================
# CONFIGURATION VARIABLES - Modify these for your project
# ====================================================================

# Project name (used in header and output messages)
PROJECT_NAME="Flutter App"

# Project structure
# Path to the Flutter web app directory (relative to the script location)
RELATIVE_WEB_APP_PATH="../project_src/visualization/web_app"

# Features to enable/disable
ENABLE_WEB_BUILD="true"      # Set to "false" to disable web builds
ENABLE_IOS_BUILD="true"     # Set to "false" to disable iOS builds
ENABLE_ANDROID_BUILD="true" # Set to "false" to disable Android builds
ENABLE_NETLIFY_DEPLOY="true" # Set to "false" to disable Netlify deployment

# Local server settings
LOCAL_SERVER_PORT="8000"

# ====================================================================
# DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
# ====================================================================

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define the web app directory (calculated from the relative path)
WEB_APP_DIR="$(dirname "$(dirname "$0")")/$(echo $RELATIVE_WEB_APP_PATH | sed 's/^\.\.\/*//')"

# Print header
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}       $PROJECT_NAME Builder          ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check Flutter installation
if ! command_exists flutter; then
  echo -e "${RED}Flutter is not installed or not in your PATH.${NC}"
  echo -e "${YELLOW}Please install Flutter from https://flutter.dev/docs/get-started/install${NC}"
  exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]\.[0-9]\+\.[0-9]\+" | cut -d' ' -f2)
echo -e "${GREEN}Flutter version: $FLUTTER_VERSION${NC}"

# Check if web_app directory exists
if [ ! -d "$WEB_APP_DIR" ]; then
  echo -e "${RED}Error: web_app directory not found at $WEB_APP_DIR.${NC}"
  exit 1
fi

# Check if pubspec.yaml exists in web_app directory
if [ ! -f "$WEB_APP_DIR/pubspec.yaml" ]; then
  echo -e "${RED}Error: pubspec.yaml not found in web_app directory.${NC}"
  exit 1
fi

# Change to web_app directory
cd "$WEB_APP_DIR"
echo -e "${BLUE}Working in directory: $(pwd)${NC}"

# Make sure dependencies are up to date
echo -e "${BLUE}Updating dependencies...${NC}"
flutter pub get

# Function to build for web
build_web() {
  echo -e "${BLUE}Building web application...${NC}"
  flutter build web --release

  if [ $? -ne 0 ]; then
    echo -e "${RED}Web build failed.${NC}"
    exit 1
  fi

  echo -e "${GREEN}Web build successful!${NC}"
}

# Function to run web app locally
run_web_locally() {
  echo -e "${BLUE}Running web application locally...${NC}"

  # Check if the build directory exists
  if [ ! -d "build/web" ]; then
    echo -e "${RED}Error: build/web directory not found. Please build the web app first.${NC}"
    return 1
  fi

  # Start a local server
  echo -e "${GREEN}Starting local web server...${NC}"
  echo -e "${YELLOW}Press Ctrl+C to stop the server when done.${NC}"

  # Check if Python is available for a simple HTTP server
  if command_exists python3; then
    echo -e "${GREEN}Server started at http://localhost:${LOCAL_SERVER_PORT}${NC}"
    echo -e "${YELLOW}Open your browser and navigate to http://localhost:${LOCAL_SERVER_PORT}${NC}"
    cd build/web && python3 -m http.server ${LOCAL_SERVER_PORT}
  elif command_exists python; then
    echo -e "${GREEN}Server started at http://localhost:${LOCAL_SERVER_PORT}${NC}"
    echo -e "${YELLOW}Open your browser and navigate to http://localhost:${LOCAL_SERVER_PORT}${NC}"
    cd build/web && python -m SimpleHTTPServer ${LOCAL_SERVER_PORT}
  elif command_exists npx; then
    echo -e "${GREEN}Server started at http://localhost:${LOCAL_SERVER_PORT}${NC}"
    echo -e "${YELLOW}Open your browser and navigate to http://localhost:${LOCAL_SERVER_PORT}${NC}"
    cd build/web && npx http-server -p ${LOCAL_SERVER_PORT}
  else
    echo -e "${RED}No suitable HTTP server found. Please install Python or Node.js.${NC}"
    return 1
  fi
}

# Function to deploy web to Netlify
deploy_web() {
  local deploy_type=$1
  local project_root="$(dirname "$(dirname "$0")")"

  echo -e "${BLUE}Deploying to Netlify...${NC}"

  # Check if Netlify CLI is installed
  if ! command_exists netlify; then
    echo -e "${YELLOW}Netlify CLI not found. Installing...${NC}"
    npm install netlify-cli -g

    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to install Netlify CLI.${NC}"
      echo -e "${YELLOW}Please install it manually: npm install netlify-cli -g${NC}"
      exit 1
    fi
  fi

  # Use provided deploy type or ask if not provided
  if [ -z "$deploy_type" ]; then
    echo ""
    echo -e "${YELLOW}Would you like to deploy as a draft or to production?${NC}"
    echo "1) Draft (preview)"
    echo "2) Production"
    read -p "Enter your choice (1/2): " deploy_type
  fi

  # We're already in the web_app directory after building
  # Just make sure we're in the right place
  cd "$WEB_APP_DIR"
  echo -e "${BLUE}Deploy path: $(pwd)/build/web${NC}"
  echo -e "${BLUE}Configuration path: $(pwd)/netlify.toml${NC}"
  echo -e "${BLUE}Build script: $(pwd)/netlify-build.sh${NC}"

  # Ensure user is logged in to Netlify
  echo -e "${YELLOW}Checking Netlify authentication status...${NC}"
  if ! netlify status; then
    echo -e "${YELLOW}You need to log in to Netlify. Starting authentication process...${NC}"
    netlify login

    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to authenticate with Netlify. Deployment aborted.${NC}"
      exit 1
    fi
  fi

  if [ "$deploy_type" = "1" ]; then
    echo -e "${YELLOW}Deploying to draft URL...${NC}"
    netlify deploy --dir=build/web
  elif [ "$deploy_type" = "2" ]; then
    echo -e "${YELLOW}Deploying to production...${NC}"
    netlify deploy --dir=build/web --prod
  else
    echo -e "${RED}Invalid choice. Deploying as draft.${NC}"
    netlify deploy --dir=build/web
  fi

  if [ $? -ne 0 ]; then
    echo -e "${RED}Netlify deployment failed.${NC}"
    exit 1
  fi

  echo -e "${GREEN}Deployment to Netlify completed!${NC}"
  echo -e "${YELLOW}Note: If this is your first deployment, you may need to configure Netlify settings:${NC}"
  echo "1. Enable Identity and Git Gateway in your Netlify site settings"
  echo "2. Set up environment variables if needed"
  echo "3. Configure custom domain if desired"
}

# Function to build for iOS
build_ios() {
  echo -e "${BLUE}Building iOS application...${NC}"

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}iOS builds can only be performed on macOS.${NC}"
    exit 1
  fi

  # Check if Xcode is installed
  if ! command_exists xcodebuild; then
    echo -e "${RED}Xcode is not installed.${NC}"
    echo -e "${YELLOW}Please install Xcode from the App Store.${NC}"
    exit 1
  fi

  # Build iOS app
  flutter build ios --release

  if [ $? -ne 0 ]; then
    echo -e "${RED}iOS build failed.${NC}"
    exit 1
  fi

  echo -e "${GREEN}iOS build successful!${NC}"
  echo -e "${YELLOW}To deploy to the App Store, open Xcode and use the Archive feature:${NC}"
  echo "1. Open the iOS project in Xcode: open ios/Runner.xcworkspace"
  echo "2. Select Product > Archive"
  echo "3. Once archiving is complete, click 'Distribute App'"
}

# Function to build for Android
build_android() {
  echo -e "${BLUE}Building Android application...${NC}"

  # Use the environment variable if set, otherwise ask for build type
  local android_choice="$ANDROID_BUILD_TYPE"
  if [ -z "$android_choice" ]; then
    echo ""
    echo -e "${YELLOW}Which Android build type would you like?${NC}"
    echo "1) APK (for direct installation)"
    echo "2) App Bundle (for Play Store)"
    read -p "Enter your choice (1/2): " android_choice
  fi

  if [ "$android_choice" = "1" ]; then
    flutter build apk --release

    if [ $? -ne 0 ]; then
      echo -e "${RED}Android APK build failed.${NC}"
      exit 1
    fi

    echo -e "${GREEN}Android APK build successful!${NC}"
    echo -e "${YELLOW}The APK file is located at:${NC}"
    echo "build/app/outputs/flutter-apk/app-release.apk"

  elif [ "$android_choice" = "2" ]; then
    flutter build appbundle --release

    if [ $? -ne 0 ]; then
      echo -e "${RED}Android App Bundle build failed.${NC}"
      exit 1
    fi

    echo -e "${GREEN}Android App Bundle build successful!${NC}"
    echo -e "${YELLOW}The App Bundle is located at:${NC}"
    echo "build/app/outputs/bundle/release/app-release.aab"
    echo -e "${YELLOW}Upload this file to the Google Play Console to publish your app.${NC}"

  else
    echo -e "${RED}Invalid choice. Building APK.${NC}"
    flutter build apk --release

    if [ $? -ne 0 ]; then
      echo -e "${RED}Android APK build failed.${NC}"
      exit 1
    fi

    echo -e "${GREEN}Android APK build successful!${NC}"
    echo -e "${YELLOW}The APK file is located at:${NC}"
    echo "build/app/outputs/flutter-apk/app-release.apk"
  fi
}

# Main script logic
# Collect all user choices upfront
echo -e "${YELLOW}Which platform would you like to build for?${NC}"
platform_options=""

if [[ $ENABLE_WEB_BUILD == "true" ]]; then
  platform_options+="1) Web\n"
fi

if [[ $ENABLE_IOS_BUILD == "true" ]]; then
  platform_options+="2) iOS\n"
fi

if [[ $ENABLE_ANDROID_BUILD == "true" ]]; then
  platform_options+="3) Android\n"
fi

platform_options+="4) All enabled platforms"

echo -e "$platform_options"
read -p "Enter your choice (1/2/3/4): " platform_choice

# Default values
deploy_web_choice="n"
run_locally_choice="n"
deploy_type=""
android_build_type=""

# Ask web-specific questions if needed
if [[ ($platform_choice == "1" || $platform_choice == "4") && $ENABLE_WEB_BUILD == "true" ]]; then
  if [[ $ENABLE_NETLIFY_DEPLOY == "true" ]]; then
    echo ""
    echo -e "${YELLOW}Would you like to deploy the web app to Netlify? (y/n)${NC}"
    read -p "Enter your choice: " deploy_web_choice

    if [[ $deploy_web_choice == "y" || $deploy_web_choice == "Y" ]]; then
      echo ""
      echo -e "${YELLOW}Would you like to deploy as a draft or to production?${NC}"
      echo "1) Draft (preview)"
      echo "2) Production"
      read -p "Enter your choice (1/2): " deploy_type
    fi
  fi

  echo ""
  echo -e "${YELLOW}Would you like to run the web app locally after building? (y/n)${NC}"
  read -p "Enter your choice: " run_locally_choice
fi

# Ask Android-specific questions if needed
if [[ ($platform_choice == "3" || $platform_choice == "4") && $ENABLE_ANDROID_BUILD == "true" ]]; then
  echo ""
  echo -e "${YELLOW}Which Android build type would you like?${NC}"
  echo "1) APK (for direct installation)"
  echo "2) App Bundle (for Play Store)"
  read -p "Enter your choice (1/2): " android_build_type
fi

# Now execute all operations based on collected choices
case $platform_choice in
  1)
    if [[ $ENABLE_WEB_BUILD == "true" ]]; then
      build_web
      if [[ $deploy_web_choice == "y" || $deploy_web_choice == "Y" ]]; then
        deploy_web "$deploy_type"
      fi

      if [[ $run_locally_choice == "y" || $run_locally_choice == "Y" ]]; then
        run_web_locally
      fi
    else
      echo -e "${RED}Web build is disabled in configuration. Exiting.${NC}"
      exit 1
    fi
    ;;
  2)
    if [[ $ENABLE_IOS_BUILD == "true" ]]; then
      build_ios
    else
      echo -e "${RED}iOS build is disabled in configuration. Exiting.${NC}"
      exit 1
    fi
    ;;
  3)
    if [[ $ENABLE_ANDROID_BUILD == "true" ]]; then
      # Pass the android build type to the function
      export ANDROID_BUILD_TYPE="$android_build_type"
      build_android
    else
      echo -e "${RED}Android build is disabled in configuration. Exiting.${NC}"
      exit 1
    fi
    ;;
  4)
    echo -e "${BLUE}Building for all enabled platforms...${NC}"

    if [[ $ENABLE_WEB_BUILD == "true" ]]; then
      build_web

      if [[ $deploy_web_choice == "y" || $deploy_web_choice == "Y" ]]; then
        deploy_web "$deploy_type"
      fi

      if [[ $run_locally_choice == "y" || $run_locally_choice == "Y" ]]; then
        run_web_locally
      fi
    fi

    if [[ $ENABLE_IOS_BUILD == "true" ]]; then
      build_ios
    fi

    if [[ $ENABLE_ANDROID_BUILD == "true" ]]; then
      # Pass the android build type to the function
      export ANDROID_BUILD_TYPE="$android_build_type"
      build_android
    fi
    ;;
  *)
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}Build process completed!${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}       $PROJECT_NAME Builder Complete         ${NC}"
echo -e "${BLUE}======================================================${NC}"
