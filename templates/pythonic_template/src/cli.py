"""
Command-line interface for the project.

This module provides CLI functionality for interacting with the project.
"""

import argparse
import logging
import sys
from pathlib import Path

from dotenv import load_dotenv

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Get the root directory of the project
ROOT_DIR = Path(__file__).parent.parent.resolve()


def setup_environment():
    """Load environment variables and configure the application."""
    env_path = ROOT_DIR / ".env"
    load_dotenv(dotenv_path=env_path)


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Project template CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Add 'version' subcommand
    version_parser = subparsers.add_parser("version", help="Display the version")

    # Add 'process' subcommand with arguments
    process_parser = subparsers.add_parser("process", help="Process a dataset")
    process_parser.add_argument("--input", "-i", required=True, help="Path to input data")
    process_parser.add_argument("--output", "-o", help="Path for output data")
    process_parser.add_argument("--config", "-c", help="Configuration file path")

    # Add 'analyze' subcommand with arguments
    analyze_parser = subparsers.add_parser("analyze", help="Analyze results")
    analyze_parser.add_argument("--input", "-i", required=True, help="Path to processed data")
    analyze_parser.add_argument("--report", "-r", help="Generate a report at the specified path")

    return parser.parse_args()


def version_command():
    """Display the version of the application."""
    # Placeholder for actual version logic
    print("Project Template v0.1.0")
    return 0


def process_command(args):
    """Process a dataset."""
    logger.info(f"Processing dataset from {args.input}")

    try:
        # Placeholder for actual processing logic
        logger.info("Processing completed successfully")
        if args.output:
            logger.info(f"Results saved to {args.output}")
        return 0
    except Exception as e:
        logger.error(f"Error processing data: {e}")
        return 1


def analyze_command(args):
    """Analyze processed data."""
    logger.info(f"Analyzing data from {args.input}")

    try:
        # Placeholder for actual analysis logic
        logger.info("Analysis completed successfully")
        if args.report:
            logger.info(f"Report generated at {args.report}")
        return 0
    except Exception as e:
        logger.error(f"Error analyzing data: {e}")
        return 1


def main():
    """Main entry point for the CLI."""
    # Parse arguments
    args = parse_arguments()

    # Load environment variables
    setup_environment()

    # Execute the requested command
    if args.command == "version":
        return version_command()
    elif args.command == "process":
        return process_command(args)
    elif args.command == "analyze":
        return analyze_command(args)
    else:
        # If no command is specified, show help
        print("Please specify a command. Use --help for more information.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
