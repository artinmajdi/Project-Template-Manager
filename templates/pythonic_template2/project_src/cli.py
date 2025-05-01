"""
Command-line interface for the Project Analysis and Visualization.

This module provides CLI functionality for interacting with the dataset,
including data processing, analysis, and launching the Streamlit dashboard.
"""

import argparse
import logging
import os
import sys
from pathlib import Path

import streamlit.web.bootstrap
from dotenv import load_dotenv

from project_src import __version__

# Setup logging
logging.basicConfig( level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", )
logger = logging.getLogger(__name__)

# Get the root directory of the project
ROOT_DIR = Path(__file__).parent.parent.resolve()


def setup_environment():
    """Load environment variables and configure the application."""
    env_path = ROOT_DIR / ".env"
    load_dotenv(dotenv_path=env_path)

    # Configure logging based on environment
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.root.setLevel(getattr(logging, log_level))


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Project Analysis and Visualization CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Add 'version' subcommand
    subparsers.add_parser("version", help="Display the version")

    # Add 'dashboard' subcommand with arguments
    dashboard_parser = subparsers.add_parser("dashboard", help="Launch the Streamlit dashboard")
    dashboard_parser.add_argument("--port", "-p", type=int, default=8501, help="Port to run the dashboard on")
    dashboard_parser.add_argument("--browser", "-b", action="store_true", help="Open dashboard in browser")

    # Add 'process' subcommand with arguments
    process_parser = subparsers.add_parser("process", help="Process a dataset")
    process_parser.add_argument("--input", "-i", required=True, help="Path to input data")
    process_parser.add_argument("--output", "-o", help="Path for output data")
    process_parser.add_argument("--config", "-c", help="Configuration file path")

    return parser.parse_args()


def version_command():
    """Display the version of the application."""
    print(f"Project Analysis and Visualization v{__version__}")
    return 0


def run_dashboard(args=None):
    """Launch the Streamlit dashboard."""
    if args is None:
        # Default arguments if called directly from entry point
        class Args:
            port = 8501
            browser = True
        args = Args()

    logger.info(f"Launching Project dashboard on port {args.port}")

    # Path to the dashboard script
    dashboard_path = Path(__file__).parent / "visualization" / "app.py"

    try:
        # Use Streamlit's bootstrap to run the dashboard
        sys.argv = ["streamlit", "run", str(dashboard_path), "--server.port", str(args.port)]
        if not args.browser:
            sys.argv.append("--server.headless")

        streamlit.web.bootstrap.run()
        return 0
    except Exception as e:
        logger.error(f"Error launching dashboard: {e}")
        return 1


def process_command(args):
    """Process a dataset."""
    logger.info(f"Processing dataset from {args.input}")

    try:
        # Import data processing module here to avoid circular imports
        from project_src.io.data_loader import DataLoader

        # Process the dataset
        data_loader = DataLoader()
        processed_data = data_loader.process_dataset(args.input, config_path=args.config)

        # Save results if output path provided
        if args.output:
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            processed_data.to_csv(output_path, index=False)
            logger.info(f"Results saved to {args.output}")

        logger.info("Processing completed successfully")
        return 0
    except Exception as e:
        logger.error(f"Error processing data: {e}")
        return 1


def analyze_command(args):
    """Analyze processed data."""
    logger.info(f"Analyzing data from {args.input}")

    try:
        # Import analysis modules here to avoid circular imports
        import pandas as pd
        from project_src.io.data_loader import DataLoader

        # Load the processed data
        data = pd.read_csv(args.input)

        # Perform analysis
        # This is a placeholder for actual analysis logic
        analysis_results = {
            "num_records": len(data),
            "num_features": len(data.columns),
            "missing_values": data.isnull().sum().sum()
        }

        # Generate report if requested
        if args.report:
            report_path = Path(args.report)
            report_path.parent.mkdir(parents=True, exist_ok=True)

            with open(report_path, 'w') as f:
                f.write("# TE-KOA-C Analysis Report\n\n")
                for key, value in analysis_results.items():
                    f.write(f"- {key}: {value}\n")

            logger.info(f"Report generated at {args.report}")

        # Generate visualizations if requested
        if args.visualize:
            logger.info("Generating visualizations...")
            # This would call visualization functions
            # For now, suggest using the dashboard
            logger.info("For detailed visualizations, use the dashboard command")

        logger.info("Analysis completed successfully")
        return 0
    except Exception as e:
        logger.error(f"Error analyzing data: {e}")
        return 1


def main():
    """Main entry point for the CLI."""
    # Parse arguments
    args = parse_arguments()

    # Execute the requested command
    if args.command == "version":
        return version_command()
    elif args.command == "dashboard":
        return run_dashboard(args)
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
