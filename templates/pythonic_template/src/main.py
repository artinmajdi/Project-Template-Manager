"""
Main application entry point.

This module serves as the primary entry point for the project. It initializes
the application configuration and starts the main process.
"""

import argparse
import logging
import os
from pathlib import Path

from dotenv import load_dotenv

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),  # Log to console
    ],
)
logger = logging.getLogger(__name__)

# Get the root directory of the project
ROOT_DIR = Path(__file__).parent.parent.resolve()


def setup_environment():
    """Load environment variables and configure the application."""
    # Look for .env file
    env_path = ROOT_DIR / ".env"
    load_dotenv(dotenv_path=env_path)

    # Configure logging based on environment
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.root.setLevel(getattr(logging, log_level))

    logger.info(f"Environment loaded from {env_path}")
    logger.info(f"Log level set to {log_level}")


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Project template application")
    parser.add_argument("--reload", action="store_true", help="Run in reload/development mode")
    parser.add_argument("--config", type=str, help="Path to configuration file")
    return parser.parse_args()


def main():
    """Main application function."""
    # Parse command line arguments
    args = parse_arguments()

    # Setup environment
    setup_environment()

    # Log startup information
    logger.info("Starting application...")
    logger.info(f"Project root directory: {ROOT_DIR}")

    # Add your application initialization code here
    if args.reload:
        logger.info("Running in development mode with auto-reload")

    # Example: Load configuration
    try:
        # Your application setup code here
        logger.info("Application initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing application: {e}")
        return 1

    # Your main application logic goes here
    try:
        logger.info("Application running. Press Ctrl+C to exit.")
        # This is where you would start your main process
        # For example, a web server, data processing pipeline, etc.

        # Example placeholder for a long-running process:
        import time
        while True:
            logger.debug("Application heartbeat")
            time.sleep(60)
    except KeyboardInterrupt:
        logger.info("Application interrupted by user")
    except Exception as e:
        logger.exception(f"Unhandled exception: {e}")
        return 1
    finally:
        logger.info("Shutting down application...")

    return 0


if __name__ == "__main__":
    exit_code = main()
    exit(exit_code)
