#!/usr/bin/env python
# -*- coding: utf-8

"""
Command-line interface for the wound analysis dashboard.
This file provides the entry points for the wound-dashboard command.
"""

import sys
import socket
from pathlib import Path
import streamlit.web.cli as stcli
from streamlit.web.cli import _main_run


def is_port_in_use(port: int) -> bool:
    """Check if a port is already in use."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0


def find_available_port(start_port: int = 8501, max_attempts: int = 10) -> int:
    """Find an available port starting from start_port.

    Args:
        start_port: The port to start checking from
        max_attempts: Maximum number of ports to check

    Returns:
        int: An available port number

    Raises:
        RuntimeError: If no available port is found after max_attempts
    """
    port = start_port
    attempts = 0
    while attempts < max_attempts:
        if not is_port_in_use(port):
            return port
        port += 1
        attempts += 1
    raise RuntimeError(f"Could not find an available port after {max_attempts} attempts")


def run_dashboard():
    """
    Run the Streamlit dashboard.
    This function is called when the user runs the wound-dashboard command.
    It uses Streamlit to run the dashboard.py file.
    """
    # Add the parent directory to sys.path to ensure imports work correctly
    parent_dir = str(Path(__file__).parent.parent)
    if parent_dir not in sys.path:
        sys.path.insert(0, parent_dir)

    # Get the path to the dashboard.py file
    dashboard_path = Path(__file__).parent / "visualization" / "app.py"

    # Find an available port
    try:
        port = find_available_port()
        print(f"Starting dashboard on port {port}...")

        # Use streamlit CLI to run the dashboard with the selected port
        sys.argv = ["streamlit", "run", "--server.port", str(port), str(dashboard_path)]
        sys.exit(stcli.main())
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)



if __name__ == "__main__":
    run_dashboard()
