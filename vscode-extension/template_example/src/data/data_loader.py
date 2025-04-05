"""
Data loading utilities for the project.

This module provides functionality for loading and preprocessing datasets from various sources.
"""

import logging
import os
from pathlib import Path
from typing import Dict, List, Optional, Union

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


class DataLoader:
    """A class for loading and preprocessing data from various sources."""

    def __init__(self, data_dir: Optional[str] = None):
        """
        Initialize the DataLoader with a data directory.

        Args:
            data_dir: Path to the data directory. If None, uses the default 'dataset' directory.
        """
        if data_dir is None:
            # Use the default dataset directory relative to the project root
            root_dir = Path(__file__).parent.parent.parent.resolve()
            self.data_dir = root_dir / "dataset"
        else:
            self.data_dir = Path(data_dir)

        # Ensure the data directory exists
        if not self.data_dir.exists():
            logger.warning(f"Data directory {self.data_dir} does not exist. Creating it.")
            os.makedirs(self.data_dir, exist_ok=True)

    def load_csv(
        self,
        filename: str,
        **kwargs
    ) -> pd.DataFrame:
        """
        Load data from a CSV file.

        Args:
            filename: Name of the CSV file (relative to data_dir)
            **kwargs: Additional arguments to pass to pd.read_csv

        Returns:
            DataFrame containing the loaded data

        Raises:
            FileNotFoundError: If the file doesn't exist
        """
        file_path = self.data_dir / filename
        logger.info(f"Loading CSV data from {file_path}")

        try:
            df = pd.read_csv(file_path, **kwargs)
            logger.info(f"Successfully loaded {len(df)} rows from {filename}")
            return df
        except FileNotFoundError:
            logger.error(f"File not found: {file_path}")
            raise
        except Exception as e:
            logger.error(f"Error loading CSV file {filename}: {e}")
            raise

    def load_excel(
        self,
        filename: str,
        sheet_name: Union[str, int, List[int], None] = 0,
        **kwargs
    ) -> Union[pd.DataFrame, Dict[str, pd.DataFrame]]:
        """
        Load data from an Excel file.

        Args:
            filename: Name of the Excel file (relative to data_dir)
            sheet_name: Name or index of the sheet(s) to load
            **kwargs: Additional arguments to pass to pd.read_excel

        Returns:
            DataFrame or dict of DataFrames containing the loaded data

        Raises:
            FileNotFoundError: If the file doesn't exist
        """
        file_path = self.data_dir / filename
        logger.info(f"Loading Excel data from {file_path}")

        try:
            df = pd.read_excel(file_path, sheet_name=sheet_name, **kwargs)
            if isinstance(df, pd.DataFrame):
                logger.info(f"Successfully loaded {len(df)} rows from {filename}")
            else:
                logger.info(f"Successfully loaded {len(df.keys())} sheets from {filename}")
            return df
        except FileNotFoundError:
            logger.error(f"File not found: {file_path}")
            raise
        except Exception as e:
            logger.error(f"Error loading Excel file {filename}: {e}")
            raise

    def load_json(self, filename: str, **kwargs) -> Union[Dict, List]:
        """
        Load data from a JSON file.

        Args:
            filename: Name of the JSON file (relative to data_dir)
            **kwargs: Additional arguments to pass to pd.read_json

        Returns:
            DataFrame containing the loaded data

        Raises:
            FileNotFoundError: If the file doesn't exist
        """
        file_path = self.data_dir / filename
        logger.info(f"Loading JSON data from {file_path}")

        try:
            df = pd.read_json(file_path, **kwargs)
            logger.info(f"Successfully loaded data from {filename}")
            return df
        except FileNotFoundError:
            logger.error(f"File not found: {file_path}")
            raise
        except Exception as e:
            logger.error(f"Error loading JSON file {filename}: {e}")
            raise

    def load_numpy(self, filename: str) -> np.ndarray:
        """
        Load data from a NumPy .npy file.

        Args:
            filename: Name of the NumPy file (relative to data_dir)

        Returns:
            NumPy array containing the loaded data

        Raises:
            FileNotFoundError: If the file doesn't exist
        """
        file_path = self.data_dir / filename
        logger.info(f"Loading NumPy data from {file_path}")

        try:
            data = np.load(file_path)
            logger.info(f"Successfully loaded NumPy array with shape {data.shape} from {filename}")
            return data
        except FileNotFoundError:
            logger.error(f"File not found: {file_path}")
            raise
        except Exception as e:
            logger.error(f"Error loading NumPy file {filename}: {e}")
            raise

    def save_csv(self, df: pd.DataFrame, filename: str, **kwargs) -> None:
        """
        Save data to a CSV file.

        Args:
            df: DataFrame to save
            filename: Name of the CSV file (relative to data_dir)
            **kwargs: Additional arguments to pass to df.to_csv
        """
        file_path = self.data_dir / filename
        logger.info(f"Saving {len(df)} rows to CSV file {file_path}")

        # Ensure directory exists
        os.makedirs(file_path.parent, exist_ok=True)

        try:
            df.to_csv(file_path, **kwargs)
            logger.info(f"Successfully saved data to {filename}")
        except Exception as e:
            logger.error(f"Error saving CSV file {filename}: {e}")
            raise
