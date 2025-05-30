# Flutter Project Build & Deploy Script Template

## Purpose
This modular script system automates the process of building, running, and deploying Flutter projects for Web, iOS, and Android. It is designed to be a configurable template that you can adapt for any Flutter project, streamlining repetitive tasks and ensuring consistent builds and deployments.

## Features
- Modular architecture for better organization and maintainability
- Configurable variables for project customization
- Checks for required tools (Flutter, Xcode, Netlify CLI, etc.)
- Updates Flutter dependencies
- Builds the project for Web, iOS, and Android platforms (each can be enabled/disabled)
- Deploys the web build to multiple targets (Netlify, Firebase)
- CI/CD integration for automated workflows
- Development utilities for testing and code generation
- Runs the web app locally with a simple HTTP server
- Interactive prompts for platform and deployment choices
- Color-coded, user-friendly terminal output

## Prerequisites

- **Flutter** installed and in your PATH ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Node.js & npm** (for Netlify CLI, Firebase CLI, and optional local server)
- **Netlify CLI** (`npm install -g netlify-cli`) if deploying to Netlify
- **Firebase CLI** (`npm install -g firebase-tools`) if deploying to Firebase
- **Xcode** (macOS only, for iOS builds)
- **Android Studio** with SDK for Android builds
- **Python** or **Node.js** for running a local web server

## Modular Architecture

The script system is organized into modules for better maintainability:

- **flutter_manager.sh** - Main entry point that coordinates all modules
- **modules/common.sh** - Shared utilities and helper functions
- **modules/web.sh** - Web-specific build and deployment functions
- **modules/mobile.sh** - iOS and Android build functions
- **modules/ci_cd.sh** - CI/CD integration for automated workflows
- **modules/dev_utils.sh** - Development utilities for testing and code generation

## Configuration

The script includes configurable variables that you can modify in the `.env` file:

```bash
# Project name and structure
PROJECT_NAME="Flutter App"
RELATIVE_APP_PATH="../src/gui/web_app"

# Flutter Configuration
FLUTTER_VERSION="3.0.0"
FLUTTER_FLAVOR=""
ADDITIONAL_BUILD_ARGS=""

# Build Configuration
ENABLE_WEB_BUILD="true"      # Set to "false" to disable web builds
ENABLE_IOS_BUILD="true"     # Set to "false" to disable iOS builds
ENABLE_ANDROID_BUILD="true" # Set to "false" to disable Android builds
LOCAL_SERVER_PORT="8000"

# Deployment Settings
ENABLE_NETLIFY_DEPLOY="true" # Set to "false" to disable Netlify deployment
ENABLE_FIREBASE_DEPLOY="false" # Set to "true" to enable Firebase deployment

# CI/CD Configuration
DEFAULT_PLATFORM="web"
DEFAULT_DEPLOY="false"
```

## Usage

### Basic Usage

1. **Place the Scripts**
   - Copy the entire `flutter` directory into your project's scripts directory.
   - Ensure the main script has execute permissions: `chmod +x flutter_manager.sh`

2. **Configure the Environment**
   - Copy `.env.template` to `.env` and edit the variables to match your project structure.
   - Set the `PROJECT_NAME` to your project's name.
   - Adjust the `RELATIVE_APP_PATH` to point to your Flutter app's location.
   - Enable/disable specific build platforms and deployment targets as needed.

3. **Run the Main Script**
   ```sh
   ./flutter_manager.sh
   ```
   - Follow the interactive prompts to choose platform(s) (Web, iOS, Android, or All enabled platforms).
   - For web: Optionally deploy to Netlify/Firebase or run locally after building.
   - For Android: Choose APK or App Bundle.
   - For iOS: Follow Xcode instructions for App Store deployment.

### Advanced Usage

#### CI/CD Integration

For automated workflows in CI/CD environments:

```sh
# Run in CI mode with default settings from .env
./flutter_manager.sh --ci

# Run with specific options
./flutter_manager.sh --ci --platform web --deploy true --deploy-target netlify --deploy-type production
```

#### Development Utilities

For development tasks:

```sh
# Run tests
./flutter_manager.sh --test

# Run build_runner for code generation
./flutter_manager.sh --build-runner

# Clean project and rebuild
./flutter_manager.sh --clean
```

## Additional Files You May Need

### .env File

The `.env` file contains all configuration options. Copy `.env.template` to `.env` and modify as needed:

```env
# Project Configuration
PROJECT_NAME=Flutter App
RELATIVE_APP_PATH=../src/gui/web_app

# API Keys and Endpoints
API_KEY=your_api_key_here
API_ENDPOINT=https://api.example.com

# Flutter Configuration
FLUTTER_VERSION=3.0.0
FLUTTER_FLAVOR=
ADDITIONAL_BUILD_ARGS=

# Build Configuration
ENABLE_WEB_BUILD=true
ENABLE_IOS_BUILD=true
ENABLE_ANDROID_BUILD=true
LOCAL_SERVER_PORT=8000

# Deployment Settings
ENABLE_NETLIFY_DEPLOY=true
NETLIFY_SITE_ID=your-netlify-site-id
NETLIFY_AUTH_TOKEN=your-netlify-auth-token

# Firebase deployment settings
ENABLE_FIREBASE_DEPLOY=false
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_TOKEN=your-firebase-token

# CI/CD Configuration
DEFAULT_PLATFORM=web
DEFAULT_DEPLOY=false
DEFAULT_DEPLOY_TARGET=netlify
DEFAULT_DEPLOY_TYPE=draft
DEFAULT_ANDROID_BUILD_TYPE=apk

# Testing Configuration
ENABLE_UNIT_TESTS=true
ENABLE_INTEGRATION_TESTS=true
ENABLE_WIDGET_TESTS=true
TEST_COVERAGE_THRESHOLD=80
```

### netlify.toml (For Netlify Deployments)

If you're using Netlify deployments, create a `netlify.toml` file in your Flutter web app directory:

```toml
[build]
  publish = "build/web"
  command = "flutter build web --release"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

## Extending the Scripts

### Adding New Modules

To add a new module:

1. Create a new script file in the `modules` directory (e.g., `modules/my_module.sh`)
2. Follow the pattern of existing modules:
   - Source the common utilities at the top
   - Define functions for your module's functionality
   - Add appropriate error handling and user feedback
3. Import your module in `flutter_manager.sh` with `source "$SCRIPT_DIR/modules/my_module.sh"`

### Customizing Existing Modules

- **Web Deployment**: Extend `web.sh` to support additional hosting providers
- **Mobile Builds**: Customize `mobile.sh` for platform-specific build options
- **CI/CD Integration**: Modify `ci_cd.sh` to integrate with your CI/CD system
- **Development Utilities**: Add new development tools to `dev_utils.sh`

### Environment Variables

Add new environment variables to `.env.template` when adding new functionality that requires configuration.

## Troubleshooting

- **Flutter Not Found**: Ensure Flutter is installed and available in your PATH.
- **Netlify CLI Issues**: Install Netlify CLI globally with `npm install -g netlify-cli`.
- **iOS Build Issues**: Only possible on macOS with Xcode installed.
- **Local Server Not Found**: Install Python or Node.js for the local HTTP server.

## Template Usage

To use this script as a template for new projects:

1. Copy it into your new project's scripts directory.
2. Configure the variables at the top of the script:

   ```bash
   PROJECT_NAME="Your Project Name"
   RELATIVE_WEB_APP_PATH="../path/to/your/flutter/app"
   ```

3. Enable/disable features based on your project requirements:

   ```bash
   ENABLE_WEB_BUILD="true"      # Set to "false" if not building for web
   ENABLE_IOS_BUILD="true"     # Set to "false" if not building for iOS
   ENABLE_ANDROID_BUILD="true" # Set to "false" if not building for Android
   ```

4. Adjust the local server port if needed:

   ```bash
   LOCAL_SERVER_PORT="8080"    # Change to your preferred port
   ```

5. Create any additional files needed (`.env`, `netlify.toml`, etc.)
6. Follow the usage steps above for building and deploying your new project.

---

For more details or customizations, review the comments within the script itself.
