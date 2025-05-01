#!/bin/bash

# ====================================================================
# WEB BUILD AND DEPLOYMENT FUNCTIONS
# ====================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to build for web
build_web() {
  local build_args="$1"
  local web_app_dir="$2"

  print_info "Building web application..."

  # Change to web_app directory if provided
  if [[ -n "$web_app_dir" ]]; then
    cd "$web_app_dir"
  fi

  # Build with additional arguments if provided
  if [[ -n "$build_args" ]]; then
    flutter build web --release $build_args
  else
    flutter build web --release
  fi

  if [ $? -ne 0 ]; then
    exit_with_error "Web build failed."
  fi

  print_success "Web build successful!"
}

# Function to run web app locally
run_web_locally() {
  local port="${1:-8000}"
  local web_app_dir="$2"

  print_info "Running web application locally..."

  # Change to web_app directory if provided
  if [[ -n "$web_app_dir" ]]; then
    cd "$web_app_dir"
  fi

  # Check if the build directory exists
  if [ ! -d "build/web" ]; then
    print_error "Error: build/web directory not found. Please build the web app first."
    return 1
  fi

  # Start a local server
  print_success "Starting local web server..."
  print_warning "Press Ctrl+C to stop the server when done."

  # Check if Python is available for a simple HTTP server
  if command_exists python3; then
    print_success "Server started at http://localhost:${port}"
    print_warning "Open your browser and navigate to http://localhost:${port}"
    cd build/web && python3 -m http.server ${port}
  elif command_exists python; then
    print_success "Server started at http://localhost:${port}"
    print_warning "Open your browser and navigate to http://localhost:${port}"
    cd build/web && python -m SimpleHTTPServer ${port}
  elif command_exists npx; then
    print_success "Server started at http://localhost:${port}"
    print_warning "Open your browser and navigate to http://localhost:${port}"
    cd build/web && npx http-server -p ${port}
  else
    print_error "No suitable HTTP server found. Please install Python or Node.js."
    return 1
  fi
}

# Function to deploy web to Netlify
deploy_web() {
  local deploy_type="$1"
  local web_app_dir="$2"

  print_info "Deploying to Netlify..."

  # Change to web_app directory if provided
  if [[ -n "$web_app_dir" ]]; then
    cd "$web_app_dir"
  fi

  # Check if Netlify CLI is installed
  if ! command_exists netlify; then
    print_warning "Netlify CLI not found. Installing..."
    npm install netlify-cli -g

    if [ $? -ne 0 ]; then
      print_error "Failed to install Netlify CLI."
      print_warning "Please install it manually: npm install netlify-cli -g"
      exit 1
    fi
  fi

  # Use provided deploy type or ask if not provided
  if [ -z "$deploy_type" ]; then
    deploy_type=$(ask_user_choice "Would you like to deploy as a draft or to production?" "1) Draft (preview)\n2) Production" "1")
  fi

  print_info "Deploy path: $(pwd)/build/web"
  print_info "Configuration path: $(pwd)/netlify.toml"

  # Ensure user is logged in to Netlify
  print_warning "Checking Netlify authentication status..."
  if ! netlify status; then
    print_warning "You need to log in to Netlify. Starting authentication process..."
    netlify login

    if [ $? -ne 0 ]; then
      exit_with_error "Failed to authenticate with Netlify. Deployment aborted."
    fi
  fi

  if [ "$deploy_type" = "1" ]; then
    print_warning "Deploying to draft URL..."
    netlify deploy --dir=build/web
  elif [ "$deploy_type" = "2" ]; then
    print_warning "Deploying to production..."
    netlify deploy --dir=build/web --prod
  else
    print_error "Invalid choice. Deploying as draft."
    netlify deploy --dir=build/web
  fi

  if [ $? -ne 0 ]; then
    exit_with_error "Netlify deployment failed."
  fi

  print_success "Deployment to Netlify completed!"
  print_warning "Note: If this is your first deployment, you may need to configure Netlify settings:"
  echo "1. Enable Identity and Git Gateway in your Netlify site settings"
  echo "2. Set up environment variables if needed"
  echo "3. Configure custom domain if desired"
}

# Function to deploy to Firebase Hosting
deploy_firebase() {
  local deploy_type="$1"
  local web_app_dir="$2"

  print_info "Deploying to Firebase Hosting..."

  # Change to web_app directory if provided
  if [[ -n "$web_app_dir" ]]; then
    cd "$web_app_dir"
  fi

  # Check if Firebase CLI is installed
  if ! command_exists firebase; then
    print_warning "Firebase CLI not found. Installing..."
    npm install -g firebase-tools

    if [ $? -ne 0 ]; then
      exit_with_error "Failed to install Firebase CLI. Please install it manually: npm install -g firebase-tools"
    fi
  fi

  # Check if firebase.json exists
  if [ ! -f "firebase.json" ]; then
    print_warning "firebase.json not found. Initializing Firebase..."
    firebase init hosting

    if [ $? -ne 0 ]; then
      exit_with_error "Failed to initialize Firebase."
    fi
  fi

  # Ensure user is logged in to Firebase
  print_warning "Checking Firebase authentication status..."
  firebase login:list > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    print_warning "You need to log in to Firebase. Starting authentication process..."
    firebase login

    if [ $? -ne 0 ]; then
      exit_with_error "Failed to authenticate with Firebase. Deployment aborted."
    fi
  fi

  # Use provided deploy type or ask if not provided
  if [ -z "$deploy_type" ]; then
    deploy_type=$(ask_user_choice "Would you like to deploy as a preview or to production?" "1) Preview\n2) Production" "1")
  fi

  if [ "$deploy_type" = "1" ]; then
    print_warning "Deploying as preview..."
    firebase hosting:channel:deploy preview --expires 7d
  elif [ "$deploy_type" = "2" ]; then
    print_warning "Deploying to production..."
    firebase deploy --only hosting
  else
    print_error "Invalid choice. Deploying as preview."
    firebase hosting:channel:deploy preview --expires 7d
  fi

  if [ $? -ne 0 ]; then
    exit_with_error "Firebase deployment failed."
  fi

  print_success "Deployment to Firebase completed!"
}
