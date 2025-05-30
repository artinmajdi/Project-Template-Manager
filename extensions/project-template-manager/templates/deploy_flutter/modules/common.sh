#!/bin/bash

# ====================================================================
# COMMON UTILITIES AND FUNCTIONS
# ====================================================================

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to load environment variables from .env file
load_env() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    echo -e "${BLUE}Loading environment variables from $env_file${NC}"
    set -a
    source "$env_file"
    set +a
  else
    echo -e "${YELLOW}No .env file found at $env_file. Using default configuration.${NC}"
  fi
}

# Function to print section header
print_section_header() {
  local title="$1"
  echo -e "\n${BLUE}======================================================${NC}"
  echo -e "${BLUE}       $title          ${NC}"
  echo -e "${BLUE}======================================================${NC}"
  echo ""
}

# Function to print success message
print_success() {
  local message="$1"
  echo -e "${GREEN}$message${NC}"
}

# Function to print info message
print_info() {
  local message="$1"
  echo -e "${BLUE}$message${NC}"
}

# Function to print warning message
print_warning() {
  local message="$1"
  echo -e "${YELLOW}$message${NC}"
}

# Function to print error message
print_error() {
  local message="$1"
  echo -e "${RED}$message${NC}"
}

# Function to exit with error
exit_with_error() {
  local message="$1"
  print_error "$message"
  exit 1
}

# Function to check Flutter installation
check_flutter_installation() {
  if ! command_exists flutter; then
    exit_with_error "Flutter is not installed or not in your PATH.\nPlease install Flutter from https://flutter.dev/docs/get-started/install"
  fi

  # Check Flutter version
  FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]\.[0-9]\+\.[0-9]\+" | cut -d' ' -f2)
  print_success "Flutter version: $FLUTTER_VERSION"
}

# Function to check project structure
check_project_structure() {
  local web_app_dir="$1"

  # Check if web_app directory exists
  if [ ! -d "$web_app_dir" ]; then
    exit_with_error "Error: Flutter app directory not found at $web_app_dir."
  fi

  # Check if pubspec.yaml exists in web_app directory
  if [ ! -f "$web_app_dir/pubspec.yaml" ]; then
    exit_with_error "Error: pubspec.yaml not found in Flutter app directory."
  fi

  print_info "Working in directory: $web_app_dir"
}

# Function to update dependencies
update_dependencies() {
  local flutter_args="$1"
  print_info "Updating dependencies..."

  if [[ -n "$flutter_args" ]]; then
    flutter pub get $flutter_args
  else
    flutter pub get
  fi

  if [ $? -ne 0 ]; then
    exit_with_error "Failed to get dependencies."
  fi
}

# Function to ask user for choice
ask_user_choice() {
  local prompt="$1"
  local options="$2"
  local default_choice="$3"

  if [[ -n "$default_choice" ]]; then
    local default_text=" (default: $default_choice)"
  else
    local default_text=""
  fi

  echo ""
  print_warning "$prompt$default_text"
  echo -e "$options"
  read -p "Enter your choice: " user_choice

  # Use default if empty
  if [[ -z "$user_choice" && -n "$default_choice" ]]; then
    user_choice="$default_choice"
  fi

  echo "$user_choice"
}

# Function to ask yes/no question
ask_yes_no() {
  local prompt="$1"
  local default_choice="$2"

  if [[ "$default_choice" == "y" ]]; then
    local default_text=" (Y/n)"
  elif [[ "$default_choice" == "n" ]]; then
    local default_text=" (y/N)"
  else
    local default_text=" (y/n)"
  fi

  echo ""
  print_warning "$prompt$default_text"
  read -p "Enter your choice: " user_choice

  # Use default if empty
  if [[ -z "$user_choice" && -n "$default_choice" ]]; then
    user_choice="$default_choice"
  fi

  if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
    echo "y"
  else
    echo "n"
  fi
}

# Function to run a command with error handling
run_command() {
  local command_description="$1"
  local command_to_run="$2"

  print_info "$command_description"
  eval "$command_to_run"

  if [ $? -ne 0 ]; then
    exit_with_error "Command failed: $command_description"
  fi
}
