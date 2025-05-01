#!/bin/bash

# ====================================================================
# FLUTTER PROJECT MANAGER
# A comprehensive script for building, testing, and deploying Flutter apps
# ====================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source module scripts
source "$SCRIPT_DIR/modules/common.sh"
source "$SCRIPT_DIR/modules/web.sh"
source "$SCRIPT_DIR/modules/mobile.sh"

# ====================================================================
# CONFIGURATION VARIABLES - Modify these for your project or use .env file
# ====================================================================

# Load environment variables from .env file if it exists
load_env "$SCRIPT_DIR/.env"

# Project name (used in header and output messages)
PROJECT_NAME="${PROJECT_NAME:-Flutter App}"

# Project structure
# Path to the Flutter app directory (relative to the script location)
RELATIVE_APP_PATH="${RELATIVE_APP_PATH:-../src/gui/web_app}"

# Features to enable/disable
ENABLE_WEB_BUILD="${ENABLE_WEB_BUILD:-true}"      # Set to "false" to disable web builds
ENABLE_IOS_BUILD="${ENABLE_IOS_BUILD:-true}"     # Set to "false" to disable iOS builds
ENABLE_ANDROID_BUILD="${ENABLE_ANDROID_BUILD:-true}" # Set to "false" to disable Android builds
ENABLE_NETLIFY_DEPLOY="${ENABLE_NETLIFY_DEPLOY:-true}" # Set to "false" to disable Netlify deployment
ENABLE_FIREBASE_DEPLOY="${ENABLE_FIREBASE_DEPLOY:-false}" # Set to "true" to enable Firebase deployment

# Build options
FLUTTER_FLAVOR="${FLUTTER_FLAVOR:-}"  # Optional build flavor
ADDITIONAL_BUILD_ARGS="${ADDITIONAL_BUILD_ARGS:-}" # Additional build arguments

# Local server settings
LOCAL_SERVER_PORT="${LOCAL_SERVER_PORT:-8000}"

# Define the app directory (calculated from the relative path)
APP_DIR="$(dirname "$SCRIPT_DIR")/$(echo $RELATIVE_APP_PATH | sed 's/^\.\.\/*//g')"

# ====================================================================
# MAIN SCRIPT LOGIC
# ====================================================================

# Print header
print_section_header "$PROJECT_NAME Manager"

# Check Flutter installation
check_flutter_installation

# Check project structure
check_project_structure "$APP_DIR"

# Change to app directory
cd "$APP_DIR"
print_info "Working in directory: $(pwd)"

# Make sure dependencies are up to date
update_dependencies

# Display available actions
print_warning "What would you like to do?"
echo "1) Build and run"
echo "2) Deploy"
echo "3) Development utilities"
echo "4) Exit"
read -p "Enter your choice (1-4): " action_choice

case $action_choice in
  1)
    # Build and run options
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

    platform_choice=$(ask_user_choice "Which platform would you like to build for?" "$platform_options" "1")

    # Default values
    deploy_web_choice="n"
    run_locally_choice="n"
    deploy_type=""
    android_build_type=""

    # Ask web-specific questions if needed
    if [[ ($platform_choice == "1" || $platform_choice == "4") && $ENABLE_WEB_BUILD == "true" ]]; then
      if [[ $ENABLE_NETLIFY_DEPLOY == "true" || $ENABLE_FIREBASE_DEPLOY == "true" ]]; then
        deploy_options=""
        if [[ $ENABLE_NETLIFY_DEPLOY == "true" ]]; then
          deploy_options+="1) Netlify\n"
        fi
        if [[ $ENABLE_FIREBASE_DEPLOY == "true" ]]; then
          deploy_options+="2) Firebase\n"
        fi
        deploy_options+="3) No deployment"

        deploy_platform=$(ask_user_choice "Would you like to deploy the web app?" "$deploy_options" "3")

        if [[ $deploy_platform == "1" || $deploy_platform == "2" ]]; then
          deploy_web_choice="y"
          deploy_type=$(ask_user_choice "Would you like to deploy as a draft or to production?" "1) Draft (preview)\n2) Production" "1")
        fi
      fi

      run_locally_choice=$(ask_yes_no "Would you like to run the web app locally after building?" "y")
    fi

    # Ask Android-specific questions if needed
    if [[ ($platform_choice == "3" || $platform_choice == "4") && $ENABLE_ANDROID_BUILD == "true" ]]; then
      android_build_type=$(ask_user_choice "Which Android build type would you like?" "1) APK (for direct installation)\n2) App Bundle (for Play Store)" "1")

      if [[ $android_build_type == "1" ]]; then
        install_apk=$(ask_yes_no "Would you like to install the APK on a connected device after building?" "n")
      fi
    fi

    # Now execute all operations based on collected choices
    case $platform_choice in
      1)
        if [[ $ENABLE_WEB_BUILD == "true" ]]; then
          build_web "$ADDITIONAL_BUILD_ARGS" "$APP_DIR"

          if [[ $deploy_web_choice == "y" ]]; then
            if [[ $deploy_platform == "1" && $ENABLE_NETLIFY_DEPLOY == "true" ]]; then
              deploy_web "$deploy_type" "$APP_DIR"
            elif [[ $deploy_platform == "2" && $ENABLE_FIREBASE_DEPLOY == "true" ]]; then
              deploy_firebase "$deploy_type" "$APP_DIR"
            fi
          fi

          if [[ $run_locally_choice == "y" ]]; then
            run_web_locally "$LOCAL_SERVER_PORT" "$APP_DIR"
          fi
        else
          exit_with_error "Web build is disabled in configuration. Exiting."
        fi
        ;;
      2)
        if [[ $ENABLE_IOS_BUILD == "true" ]]; then
          build_ios "$ADDITIONAL_BUILD_ARGS" "$APP_DIR" "$FLUTTER_FLAVOR"

          open_project=$(ask_yes_no "Would you like to open the iOS project in Xcode?" "y")
          if [[ $open_project == "y" ]]; then
            open_ios_project "$APP_DIR"
          fi
        else
          exit_with_error "iOS build is disabled in configuration. Exiting."
        fi
        ;;
      3)
        if [[ $ENABLE_ANDROID_BUILD == "true" ]]; then
          build_android "$android_build_type" "$APP_DIR" "$FLUTTER_FLAVOR" "$ADDITIONAL_BUILD_ARGS"

          if [[ $android_build_type == "1" && $install_apk == "y" ]]; then
            install_android_apk "$APP_DIR" "$FLUTTER_FLAVOR"
          fi
        else
          exit_with_error "Android build is disabled in configuration. Exiting."
        fi
        ;;
      4)
        print_info "Building for all enabled platforms..."

        if [[ $ENABLE_WEB_BUILD == "true" ]]; then
          build_web "$ADDITIONAL_BUILD_ARGS" "$APP_DIR"

          if [[ $deploy_web_choice == "y" ]]; then
            if [[ $deploy_platform == "1" && $ENABLE_NETLIFY_DEPLOY == "true" ]]; then
              deploy_web "$deploy_type" "$APP_DIR"
            elif [[ $deploy_platform == "2" && $ENABLE_FIREBASE_DEPLOY == "true" ]]; then
              deploy_firebase "$deploy_type" "$APP_DIR"
            fi
          fi

          if [[ $run_locally_choice == "y" ]]; then
            run_web_locally "$LOCAL_SERVER_PORT" "$APP_DIR"
          fi
        fi

        if [[ $ENABLE_IOS_BUILD == "true" ]]; then
          build_ios "$ADDITIONAL_BUILD_ARGS" "$APP_DIR" "$FLUTTER_FLAVOR"
        fi

        if [[ $ENABLE_ANDROID_BUILD == "true" ]]; then
          build_android "$android_build_type" "$APP_DIR" "$FLUTTER_FLAVOR" "$ADDITIONAL_BUILD_ARGS"

          if [[ $android_build_type == "1" && $install_apk == "y" ]]; then
            install_android_apk "$APP_DIR" "$FLUTTER_FLAVOR"
          fi
        fi
        ;;
      *)
        exit_with_error "Invalid choice. Exiting."
        ;;
    esac
    ;;

  2)
    # Deploy options
    deploy_options=""

    if [[ $ENABLE_WEB_BUILD == "true" ]]; then
      if [[ $ENABLE_NETLIFY_DEPLOY == "true" ]]; then
        deploy_options+="1) Deploy to Netlify\n"
      fi

      if [[ $ENABLE_FIREBASE_DEPLOY == "true" ]]; then
        deploy_options+="2) Deploy to Firebase\n"
      fi
    fi

    deploy_options+="3) Back to main menu"

    deploy_choice=$(ask_user_choice "Select deployment option:" "$deploy_options" "3")

    case $deploy_choice in
      1)
        if [[ $ENABLE_NETLIFY_DEPLOY == "true" ]]; then
          # Check if web build exists
          if [ ! -d "$APP_DIR/build/web" ]; then
            print_warning "Web build not found. Building web app first..."
            build_web "$ADDITIONAL_BUILD_ARGS" "$APP_DIR"
          fi

          deploy_type=$(ask_user_choice "Would you like to deploy as a draft or to production?" "1) Draft (preview)\n2) Production" "1")
          deploy_web "$deploy_type" "$APP_DIR"
        else
          exit_with_error "Netlify deployment is disabled in configuration. Exiting."
        fi
        ;;
      2)
        if [[ $ENABLE_FIREBASE_DEPLOY == "true" ]]; then
          # Check if web build exists
          if [ ! -d "$APP_DIR/build/web" ]; then
            print_warning "Web build not found. Building web app first..."
            build_web "$ADDITIONAL_BUILD_ARGS" "$APP_DIR"
          fi

          deploy_type=$(ask_user_choice "Would you like to deploy as a preview or to production?" "1) Preview\n2) Production" "1")
          deploy_firebase "$deploy_type" "$APP_DIR"
        else
          exit_with_error "Firebase deployment is disabled in configuration. Exiting."
        fi
        ;;
      3)
        # Return to main menu by re-running the script
        exec "$0"
        ;;
      *)
        exit_with_error "Invalid choice. Exiting."
        ;;
    esac
    ;;

  3)
    # Development utilities
    print_warning "Development utilities:"
    echo "1) Run Flutter tests"
    echo "2) Generate code (build_runner)"
    echo "3) Analyze code"
    echo "4) Clean project"
    echo "5) Back to main menu"
    read -p "Enter your choice (1-5): " dev_choice

    case $dev_choice in
      1)
        print_info "Running Flutter tests..."
        cd "$APP_DIR"
        flutter test
        ;;
      2)
        print_info "Running build_runner..."
        cd "$APP_DIR"
        flutter pub run build_runner build --delete-conflicting-outputs
        ;;
      3)
        print_info "Analyzing code..."
        cd "$APP_DIR"
        flutter analyze
        ;;
      4)
        print_info "Cleaning project..."
        cd "$APP_DIR"
        flutter clean
        print_info "Updating dependencies..."
        flutter pub get
        ;;
      5)
        # Return to main menu by re-running the script
        exec "$0"
        ;;
      *)
        exit_with_error "Invalid choice. Exiting."
        ;;
    esac
    ;;

  4)
    print_info "Exiting..."
    exit 0
    ;;

  *)
    exit_with_error "Invalid choice. Exiting."
    ;;
esac

print_section_header "$PROJECT_NAME Manager Complete"
