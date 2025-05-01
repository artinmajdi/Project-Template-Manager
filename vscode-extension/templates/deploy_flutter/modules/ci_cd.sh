#!/bin/bash

# ====================================================================
# CI/CD INTEGRATION FUNCTIONS
# Functions for continuous integration and deployment workflows
# ====================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to run in CI mode (non-interactive)
run_ci_workflow() {
  local app_dir="$1"
  local platform="${DEFAULT_PLATFORM:-web}"
  local deploy="${DEFAULT_DEPLOY:-false}"
  local deploy_target="${DEFAULT_DEPLOY_TARGET:-netlify}"
  local deploy_type="${DEFAULT_DEPLOY_TYPE:-draft}"
  local android_build_type="${DEFAULT_ANDROID_BUILD_TYPE:-apk}"

  print_info "Running in CI mode with the following configuration:"
  print_info "Platform: $platform"
  print_info "Deploy: $deploy"

  if [[ "$deploy" == "true" ]]; then
    print_info "Deploy target: $deploy_target"
    print_info "Deploy type: $deploy_type"
  fi

  if [[ "$platform" == "android" || "$platform" == "all" ]]; then
    print_info "Android build type: $android_build_type"
  fi

  # Source required modules based on platform
  if [[ "$platform" == "web" || "$platform" == "all" ]]; then
    source "$SCRIPT_DIR/web.sh"
  fi

  if [[ "$platform" == "ios" || "$platform" == "android" || "$platform" == "all" ]]; then
    source "$SCRIPT_DIR/mobile.sh"
  fi

  # Execute build based on platform
  case $platform in
    web)
      build_web "$ADDITIONAL_BUILD_ARGS" "$app_dir"

      if [[ "$deploy" == "true" ]]; then
        if [[ "$deploy_target" == "netlify" && "$ENABLE_NETLIFY_DEPLOY" == "true" ]]; then
          deploy_web "$deploy_type" "$app_dir"
        elif [[ "$deploy_target" == "firebase" && "$ENABLE_FIREBASE_DEPLOY" == "true" ]]; then
          deploy_firebase "$deploy_type" "$app_dir"
        else
          print_warning "Deployment target $deploy_target is not enabled or not recognized."
        fi
      fi
      ;;
    ios)
      if [[ "$(uname)" != "Darwin" ]]; then
        exit_with_error "iOS builds can only be performed on macOS."
      fi

      build_ios "$ADDITIONAL_BUILD_ARGS" "$app_dir" "$FLUTTER_FLAVOR"
      ;;
    android)
      build_android "$android_build_type" "$app_dir" "$FLUTTER_FLAVOR" "$ADDITIONAL_BUILD_ARGS"
      ;;
    all)
      if [[ "$ENABLE_WEB_BUILD" == "true" ]]; then
        build_web "$ADDITIONAL_BUILD_ARGS" "$app_dir"

        if [[ "$deploy" == "true" ]]; then
          if [[ "$deploy_target" == "netlify" && "$ENABLE_NETLIFY_DEPLOY" == "true" ]]; then
            deploy_web "$deploy_type" "$app_dir"
          elif [[ "$deploy_target" == "firebase" && "$ENABLE_FIREBASE_DEPLOY" == "true" ]]; then
            deploy_firebase "$deploy_type" "$app_dir"
          fi
        fi
      fi

      if [[ "$ENABLE_IOS_BUILD" == "true" && "$(uname)" == "Darwin" ]]; then
        build_ios "$ADDITIONAL_BUILD_ARGS" "$app_dir" "$FLUTTER_FLAVOR"
      fi

      if [[ "$ENABLE_ANDROID_BUILD" == "true" ]]; then
        build_android "$android_build_type" "$app_dir" "$FLUTTER_FLAVOR" "$ADDITIONAL_BUILD_ARGS"
      fi
      ;;
    *)
      exit_with_error "Invalid platform: $platform. Supported platforms: web, ios, android, all"
      ;;
  esac
}

# Function to setup GitHub Actions workflow
setup_github_actions() {
  local app_dir="$1"
  local github_dir="$app_dir/.github/workflows"

  print_info "Setting up GitHub Actions workflow..."

  # Create directory if it doesn't exist
  mkdir -p "$github_dir"

  # Create workflow file
  cat > "$github_dir/flutter_ci.yml" << 'EOF'
name: Flutter CI/CD

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]
  workflow_dispatch:
    inputs:
      platform:
        description: 'Platform to build (web, ios, android, all)'
        required: true
        default: 'web'
      deploy:
        description: 'Deploy after build'
        required: false
        default: 'false'
      deploy_target:
        description: 'Deployment target (netlify, firebase)'
        required: false
        default: 'netlify'
      deploy_type:
        description: 'Deployment type (draft, production)'
        required: false
        default: 'draft'

jobs:
  build:
    runs-on: ${{ (github.event.inputs.platform == 'ios' || github.event.inputs.platform == 'all') && 'macos-latest' || 'ubuntu-latest' }}

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
        channel: 'stable'

    - name: Install dependencies
      run: flutter pub get
      working-directory: ./src/gui/web_app  # Update this path to match your project structure

    - name: Run tests
      run: flutter test
      working-directory: ./src/gui/web_app  # Update this path to match your project structure

    - name: Setup environment
      run: |
        cp ./vscode-extension/templates/scripts/flutter/.env.template ./vscode-extension/templates/scripts/flutter/.env
        echo "CI_MODE=true" >> ./vscode-extension/templates/scripts/flutter/.env
        echo "DEFAULT_PLATFORM=${{ github.event.inputs.platform || 'web' }}" >> ./vscode-extension/templates/scripts/flutter/.env
        echo "DEFAULT_DEPLOY=${{ github.event.inputs.deploy || 'false' }}" >> ./vscode-extension/templates/scripts/flutter/.env
        echo "DEFAULT_DEPLOY_TARGET=${{ github.event.inputs.deploy_target || 'netlify' }}" >> ./vscode-extension/templates/scripts/flutter/.env
        echo "DEFAULT_DEPLOY_TYPE=${{ github.event.inputs.deploy_type || 'draft' }}" >> ./vscode-extension/templates/scripts/flutter/.env

    - name: Build and deploy
      run: |
        chmod +x ./vscode-extension/templates/scripts/flutter/flutter_manager.sh
        ./vscode-extension/templates/scripts/flutter/flutter_manager.sh
      env:
        NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
        FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
EOF

  print_success "GitHub Actions workflow created at $github_dir/flutter_ci.yml"
  print_warning "Note: You need to set up the following secrets in your GitHub repository:"
  echo "- NETLIFY_AUTH_TOKEN: Your Netlify authentication token (if using Netlify)"
  echo "- FIREBASE_TOKEN: Your Firebase CLI token (if using Firebase)"
}

# Function to setup GitLab CI configuration
setup_gitlab_ci() {
  local app_dir="$1"

  print_info "Setting up GitLab CI configuration..."

  # Create GitLab CI configuration file
  cat > "$app_dir/.gitlab-ci.yml" << 'EOF'
stages:
  - test
  - build
  - deploy

variables:
  FLUTTER_VERSION: "3.x"

.flutter_setup: &flutter_setup
  before_script:
    - apt-get update -y
    - apt-get install -y curl git unzip xz-utils zip libglu1-mesa
    - git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
    - export PATH=$PATH:/flutter/bin
    - flutter doctor
    - flutter pub get

test:
  stage: test
  image: ubuntu:latest
  <<: *flutter_setup
  script:
    - flutter test
  only:
    - main
    - master
    - develop
    - merge_requests

build_web:
  stage: build
  image: ubuntu:latest
  <<: *flutter_setup
  script:
    - flutter build web --release
  artifacts:
    paths:
      - build/web/
  only:
    - main
    - master
    - develop
    - merge_requests

build_android:
  stage: build
  image: ubuntu:latest
  <<: *flutter_setup
  script:
    - flutter build apk --release
  artifacts:
    paths:
      - build/app/outputs/flutter-apk/app-release.apk
  only:
    - main
    - master
    - develop

deploy_web_preview:
  stage: deploy
  image: node:latest
  dependencies:
    - build_web
  script:
    - npm install -g netlify-cli
    - netlify deploy --dir=build/web --auth=$NETLIFY_AUTH_TOKEN --site=$NETLIFY_SITE_ID
  only:
    - develop
  environment:
    name: preview
    url: https://preview.example.com

deploy_web_production:
  stage: deploy
  image: node:latest
  dependencies:
    - build_web
  script:
    - npm install -g netlify-cli
    - netlify deploy --dir=build/web --auth=$NETLIFY_AUTH_TOKEN --site=$NETLIFY_SITE_ID --prod
  only:
    - main
    - master
  environment:
    name: production
    url: https://example.com
EOF

  print_success "GitLab CI configuration created at $app_dir/.gitlab-ci.yml"
  print_warning "Note: You need to set up the following CI/CD variables in your GitLab project:"
  echo "- NETLIFY_AUTH_TOKEN: Your Netlify authentication token"
  echo "- NETLIFY_SITE_ID: Your Netlify site ID"
}

# Function to setup Bitbucket Pipelines configuration
setup_bitbucket_pipelines() {
  local app_dir="$1"

  print_info "Setting up Bitbucket Pipelines configuration..."

  # Create Bitbucket Pipelines configuration file
  cat > "$app_dir/bitbucket-pipelines.yml" << 'EOF'
image: ubuntu:latest

definitions:
  caches:
    flutter: /flutter

pipelines:
  default:
    - step:
        name: Test
        caches:
          - flutter
        script:
          - apt-get update -y
          - apt-get install -y curl git unzip xz-utils zip libglu1-mesa
          - git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
          - export PATH=$PATH:/flutter/bin
          - flutter doctor
          - flutter pub get
          - flutter test
  branches:
    master:
      - step:
          name: Build Web
          caches:
            - flutter
          script:
            - apt-get update -y
            - apt-get install -y curl git unzip xz-utils zip libglu1-mesa
            - git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
            - export PATH=$PATH:/flutter/bin
            - flutter doctor
            - flutter pub get
            - flutter build web --release
          artifacts:
            - build/web/**
      - step:
          name: Deploy to Production
          deployment: Production
          script:
            - pipe: atlassian/netlify-deploy:0.3.0
              variables:
                NETLIFY_AUTH_TOKEN: $NETLIFY_AUTH_TOKEN
                NETLIFY_SITE_ID: $NETLIFY_SITE_ID
                NETLIFY_DEPLOY_PATH: 'build/web'
                NETLIFY_DEPLOY_MESSAGE: 'Deployed from Bitbucket Pipelines'
                NETLIFY_PRODUCTION: 'true'
    develop:
      - step:
          name: Build Web
          caches:
            - flutter
          script:
            - apt-get update -y
            - apt-get install -y curl git unzip xz-utils zip libglu1-mesa
            - git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
            - export PATH=$PATH:/flutter/bin
            - flutter doctor
            - flutter pub get
            - flutter build web --release
          artifacts:
            - build/web/**
      - step:
          name: Deploy to Staging
          deployment: Staging
          script:
            - pipe: atlassian/netlify-deploy:0.3.0
              variables:
                NETLIFY_AUTH_TOKEN: $NETLIFY_AUTH_TOKEN
                NETLIFY_SITE_ID: $NETLIFY_SITE_ID
                NETLIFY_DEPLOY_PATH: 'build/web'
                NETLIFY_DEPLOY_MESSAGE: 'Deployed from Bitbucket Pipelines'
EOF

  print_success "Bitbucket Pipelines configuration created at $app_dir/bitbucket-pipelines.yml"
  print_warning "Note: You need to set up the following repository variables in Bitbucket:"
  echo "- NETLIFY_AUTH_TOKEN: Your Netlify authentication token"
  echo "- NETLIFY_SITE_ID: Your Netlify site ID"
}
