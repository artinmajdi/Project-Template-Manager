"""
Configuration utilities for the project.

This module provides functionality for loading configuration from various sources.
"""

import logging
import os
from pathlib import Path
from typing import Any, Dict, Optional

import yaml
from dotenv import load_dotenv

logger = logging.getLogger(__name__)


class Config:
    """A class for loading and accessing configuration settings."""

    def __init__(self, config_path: Optional[str] = None, env_file: Optional[str] = None):
        """
        Initialize the Config with optional config file and environment file paths.

        Args:
            config_path: Path to the YAML config file. If None, uses the default config.yaml
            env_file: Path to the .env file. If None, uses the default .env in project root
        """
        # Load environment variables
        if env_file is None:
            # Use the default .env file in the project root
            root_dir = Path(__file__).parent.parent.parent.resolve()
            env_path = root_dir / ".env"
        else:
            env_path = Path(env_file)

        if env_path.exists():
            load_dotenv(dotenv_path=env_path)
            logger.info(f"Loaded environment variables from {env_path}")

        # Load configuration from YAML file
        if config_path is None:
            # Use the default config.yaml in the same directory as this module
            config_path = Path(__file__).parent / "config.yaml"
        else:
            config_path = Path(config_path)

        self.config: Dict[str, Any] = {}

        if config_path.exists():
            try:
                with open(config_path, 'r') as file:
                    self.config = yaml.safe_load(file)
                logger.info(f"Loaded configuration from {config_path}")
            except Exception as e:
                logger.error(f"Error loading configuration file: {e}")
        else:
            logger.warning(f"Configuration file not found: {config_path}")

    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a configuration value by key.

        Args:
            key: The configuration key to look up
            default: The default value to return if the key is not found

        Returns:
            The configuration value for the key, or the default value
        """
        # First check if the key exists in environment variables
        env_key = key.upper().replace('.', '_')
        env_value = os.environ.get(env_key)
        if env_value is not None:
            return env_value

        # Otherwise look in the config dictionary
        keys = key.split('.')
        value = self.config

        try:
            for k in keys:
                value = value[k]
            return value
        except (KeyError, TypeError):
            return default

    def get_int(self, key: str, default: Optional[int] = None) -> Optional[int]:
        """Get a configuration value as an integer."""
        value = self.get(key, default)
        if value is None:
            return None
        return int(value)

    def get_float(self, key: str, default: Optional[float] = None) -> Optional[float]:
        """Get a configuration value as a float."""
        value = self.get(key, default)
        if value is None:
            return None
        return float(value)

    def get_bool(self, key: str, default: Optional[bool] = None) -> Optional[bool]:
        """Get a configuration value as a boolean."""
        value = self.get(key, default)
        if value is None:
            return None

        if isinstance(value, bool):
            return value

        # Handle string values
        if isinstance(value, str):
            return value.lower() in ('true', 'yes', '1', 'y', 't')

        # Handle numeric values
        return bool(value)


# Singleton instance
_config_instance = None


def get_config(config_path: Optional[str] = None, env_file: Optional[str] = None) -> Config:
    """
    Get the singleton Config instance.

    Args:
        config_path: Optional path to config file
        env_file: Optional path to .env file

    Returns:
        Singleton Config instance
    """
    global _config_instance
    if _config_instance is None:
        _config_instance = Config(config_path, env_file)
    return _config_instance
