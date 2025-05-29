"""
Project Analysis and Visualization

A data science and machine learning framework for nursing research.
"""

# Configure logging
from .configuration.settings import setup_logging, logger

# Set up default logging when the package is imported
setup_logging()


from .configuration import params, Settings, ConfigManager
from .visualization import Dashboard
from .io import DataLoader


__all__ = ['Dashboard', 'DataLoader', 'params', 'Settings', 'ConfigManager']
