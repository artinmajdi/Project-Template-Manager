#!/bin/bash

# Initialize default values
ENV_FILE=".env"
BUILD_FLAG=""
DETACH_FLAG="-d"
CACHE_FLAG=""

# Parse command line arguments
COMMAND=""
COMMAND_ARGS=""

# Function to show usage
show_usage() {
  echo "Usage: ./scripts/run_docker.sh [start|stop|restart|build|logs|shell] [options]"
  echo ""
  echo "Options:"
  echo "  --env-file PATH   Specify a custom .env file location"
  echo "  --build           Force rebuild of containers"
  echo "  --detach          Run containers in detached mode (default)"
  echo "  --no-detach       Run containers in foreground"
  echo "  --no-cache        Build without using cache"
  exit 1
}

# Check if no arguments were provided
if [ $# -eq 0 ]; then
  show_usage
fi

# Get the command (first argument)
COMMAND=$1
shift

# Process remaining arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      if [ -z "$2" ] || [[ "$2" == --* ]]; then
        echo "Error: --env-file requires a value"
        exit 1
      fi
      ENV_FILE="$2"
      shift 2
      ;;
    --env-file=*)
      ENV_FILE="${1#*=}"
      shift
      ;;
    --build)
      BUILD_FLAG="--build"
      shift
      ;;
    --detach)
      DETACH_FLAG="-d"
      shift
      ;;
    --no-detach)
      DETACH_FLAG=""
      shift
      ;;
    --no-cache)
      CACHE_FLAG="--no-cache"
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      show_usage
      ;;
    *)
      # Collect remaining args for command
      COMMAND_ARGS="$COMMAND_ARGS $1"
      shift
      ;;
  esac
done

# Navigate to the project root directory
cd "$(dirname "$0")/.."
ROOT_DIR=$(pwd)

# Check docker-compose path
COMPOSE_FILE_PATH="$ROOT_DIR/setup_config/docker/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE_PATH" ]; then
  # Try alternate location
  COMPOSE_FILE_PATH="$ROOT_DIR/docker/docker-compose.yml"
  if [ ! -f "$COMPOSE_FILE_PATH" ]; then
    echo "Error: Could not find docker-compose.yml in either setup_config/docker/ or docker/ directories."
    exit 1
  fi
fi

# Check if the specified .env file exists
if [ ! -f "$ROOT_DIR/$ENV_FILE" ]; then
  echo "Warning: $ENV_FILE file not found."
  echo "Some features may not work properly without environment variables."
  echo "You can create one based on .env.example if available."
fi

# Define actions
case $COMMAND in
  start)
    echo "Starting Docker containers..."
    # Use --env-file to explicitly point to the .env file
    if [ -n "$BUILD_FLAG" ]; then
      echo "Rebuilding containers before starting..."
    fi

    if [ -f "$ROOT_DIR/$ENV_FILE" ]; then
      docker compose -f "$COMPOSE_FILE_PATH" --env-file "$ROOT_DIR/$ENV_FILE" up $BUILD_FLAG $CACHE_FLAG $DETACH_FLAG
    else
      docker compose -f "$COMPOSE_FILE_PATH" up $BUILD_FLAG $CACHE_FLAG $DETACH_FLAG
    fi

    if [ -n "$DETACH_FLAG" ]; then
      echo " ✅ Docker containers started successfully."
      echo " 🌐 You can now access the application at http://localhost:8000/"
    fi
    ;;
  stop)
    echo "Stopping Docker containers..."
    docker compose -f "$COMPOSE_FILE_PATH" down
    ;;
  restart)
    echo "Restarting Docker containers..."
    if [ -f "$ROOT_DIR/$ENV_FILE" ]; then
      docker compose -f "$COMPOSE_FILE_PATH" --env-file "$ROOT_DIR/$ENV_FILE" restart
    else
      docker compose -f "$COMPOSE_FILE_PATH" restart
    fi
    ;;
  build)
    echo "Building Docker images..."
    if [ -f "$ROOT_DIR/$ENV_FILE" ]; then
      docker compose -f "$COMPOSE_FILE_PATH" --env-file "$ROOT_DIR/$ENV_FILE" build $CACHE_FLAG
    else
      docker compose -f "$COMPOSE_FILE_PATH" build $CACHE_FLAG
    fi
    ;;
  logs)
    echo "Showing Docker logs..."
    docker compose -f "$COMPOSE_FILE_PATH" logs -f
    ;;
  shell)
    echo "Opening a shell in the container..."
    if [ -f "$ROOT_DIR/$ENV_FILE" ]; then
      docker compose -f "$COMPOSE_FILE_PATH" --env-file "$ROOT_DIR/$ENV_FILE" exec app /bin/bash || docker compose -f "$COMPOSE_FILE_PATH" --env-file "$ROOT_DIR/$ENV_FILE" exec app /bin/sh
    else
      docker compose -f "$COMPOSE_FILE_PATH" exec app /bin/bash || docker compose -f "$COMPOSE_FILE_PATH" exec app /bin/sh
    fi
    ;;
  *)
    echo "Unknown command: $COMMAND"
    show_usage
    ;;
esac
