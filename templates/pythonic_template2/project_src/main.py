"""
Main application entry point for Project Analysis and Visualization.

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
    handlers=[logging.StreamHandler()],
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
    parser = argparse.ArgumentParser(description="Project Analysis and Visualization")
    parser.add_argument("--reload", action="store_true", help="Run in reload/development mode")
    parser.add_argument("--config", type=str, help="Path to configuration file")
    parser.add_argument("--dashboard", action="store_true", help="Launch the Streamlit dashboard")
    parser.add_argument("--port", type=int, default=8501, help="Port for the Streamlit dashboard (if --dashboard is used)")
    return parser.parse_args()


def main():
    """Main application function."""
    # Parse command line arguments
    args = parse_arguments()

    # # Setup environment
    # setup_environment()

    # Log startup information
    logger.info("Starting Project Analysis and Visualization...")
    logger.info(f"Project root directory: {ROOT_DIR}")

    # If dashboard flag is set, launch the Streamlit dashboard
    if args.dashboard:
        from project_src.cli import run_dashboard

        class DashboardArgs:
            port = args.port
            browser = True

        return run_dashboard(DashboardArgs())

    # Add your application initialization code here
    if args.reload:
        logger.info("Running in development mode with auto-reload")

    # Example: Load configuration
    try:
        # Load configuration if specified
        config_path = args.config if args.config else ROOT_DIR / "setup_config" / "default_config.yaml"
        logger.info(f"Loading configuration from {config_path}")

        # Your configuration loading code here
        # For example:
        # from project_src.configurations.config_loader import ConfigLoader
        # config = ConfigLoader().load(config_path)

        logger.info("Application initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing application: {e}")
        return 1

    # Your main application logic goes here
    try:
        logger.info("Project Analysis and Visualization application running. Press Ctrl+C to exit.")

        # Import and initialize necessary components
        from project_src.io.data_loader import DataLoader

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
