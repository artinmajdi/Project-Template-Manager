#!/bin/bash

# ====================================================================
# DEVELOPMENT UTILITIES
# Helper functions for Flutter development tasks
# ====================================================================

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to run Flutter tests
run_tests() {
  local app_dir="$1"
  local test_args="$2"

  print_info "Running Flutter tests..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Run tests with additional arguments if provided
  if [[ -n "$test_args" ]]; then
    flutter test $test_args
  else
    flutter test
  fi

  if [ $? -ne 0 ]; then
    print_error "Tests failed."
    return 1
  else
    print_success "Tests completed successfully!"
  fi
}

# Function to run build_runner
run_build_runner() {
  local app_dir="$1"
  local build_runner_args="$2"

  print_info "Running build_runner..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Check if build_runner is in dependencies
  if ! grep -q "build_runner" pubspec.yaml; then
    print_warning "build_runner not found in dependencies. Adding it..."
    flutter pub add --dev build_runner
  fi

  # Run build_runner with additional arguments if provided
  if [[ -n "$build_runner_args" ]]; then
    flutter pub run build_runner build $build_runner_args
  else
    flutter pub run build_runner build --delete-conflicting-outputs
  fi

  if [ $? -ne 0 ]; then
    print_error "build_runner failed."
    return 1
  else
    print_success "Code generation completed successfully!"
  fi
}

# Function to analyze code
analyze_code() {
  local app_dir="$1"
  local analyze_args="$2"

  print_info "Analyzing Flutter code..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Run analyzer with additional arguments if provided
  if [[ -n "$analyze_args" ]]; then
    flutter analyze $analyze_args
  else
    flutter analyze
  fi

  if [ $? -ne 0 ]; then
    print_error "Code analysis found issues."
    return 1
  else
    print_success "Code analysis completed successfully! No issues found."
  fi
}

# Function to clean project
clean_project() {
  local app_dir="$1"

  print_info "Cleaning Flutter project..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  flutter clean

  if [ $? -ne 0 ]; then
    print_error "Project cleaning failed."
    return 1
  fi

  print_info "Updating dependencies..."
  flutter pub get

  if [ $? -ne 0 ]; then
    print_error "Failed to get dependencies."
    return 1
  fi

  print_success "Project cleaned successfully!"
}

# Function to format code
format_code() {
  local app_dir="$1"
  local format_args="$2"

  print_info "Formatting Flutter code..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Run formatter with additional arguments if provided
  if [[ -n "$format_args" ]]; then
    flutter format lib test $format_args
  else
    flutter format lib test
  fi

  if [ $? -ne 0 ]; then
    print_error "Code formatting failed."
    return 1
  else
    print_success "Code formatting completed successfully!"
  fi
}

# Function to run Flutter doctor
run_doctor() {
  local app_dir="$1"

  print_info "Running Flutter doctor..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  flutter doctor -v

  if [ $? -ne 0 ]; then
    print_warning "Flutter doctor found issues that may need to be addressed."
  else
    print_success "Flutter environment is set up correctly!"
  fi
}

# Function to update Flutter and dependencies
update_flutter() {
  local app_dir="$1"

  print_info "Updating Flutter..."

  # Update Flutter SDK
  flutter upgrade

  if [ $? -ne 0 ]; then
    print_error "Flutter upgrade failed."
    return 1
  fi

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"

    print_info "Updating project dependencies..."
    flutter pub upgrade

    if [ $? -ne 0 ]; then
      print_error "Dependency upgrade failed."
      return 1
    fi
  fi

  print_success "Flutter and dependencies updated successfully!"
}

# Function to generate localization files
generate_localizations() {
  local app_dir="$1"

  print_info "Generating localization files..."

  # Change to app directory if provided
  if [[ -n "$app_dir" ]]; then
    cd "$app_dir"
  fi

  # Check if flutter_localizations is in dependencies
  if ! grep -q "flutter_localizations" pubspec.yaml; then
    print_warning "flutter_localizations not found in dependencies. Adding it..."
    flutter pub add flutter_localizations --sdk=flutter
  fi

  # Generate localization files
  flutter gen-l10n

  if [ $? -ne 0 ]; then
    print_error "Localization generation failed."
    return 1
  else
    print_success "Localization files generated successfully!"
  fi
}
