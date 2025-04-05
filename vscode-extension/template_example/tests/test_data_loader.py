"""
Tests for the data loader module.

This module contains tests for the DataLoader class.
"""

import os
import tempfile
from pathlib import Path
from unittest import TestCase, mock

import numpy as np
import pandas as pd
import pytest

from src.data.data_loader import DataLoader


class TestDataLoader(TestCase):
    """Test cases for the DataLoader class."""

    def setUp(self):
        """Set up test fixtures."""
        # Create a temporary directory for test data
        self.temp_dir = tempfile.TemporaryDirectory()
        self.data_dir = Path(self.temp_dir.name)

        # Create a DataLoader instance with the temp directory
        self.loader = DataLoader(data_dir=self.data_dir)

        # Create test data files
        self._create_test_files()

    def tearDown(self):
        """Clean up test fixtures."""
        self.temp_dir.cleanup()

    def _create_test_files(self):
        """Create test data files in the temporary directory."""
        # Create a CSV file
        csv_data = pd.DataFrame({
            'A': [1, 2, 3],
            'B': ['x', 'y', 'z']
        })
        csv_data.to_csv(self.data_dir / 'test.csv', index=False)

        # Create a JSON file
        json_data = pd.DataFrame({
            'C': [4, 5, 6],
            'D': ['a', 'b', 'c']
        })
        json_data.to_json(self.data_dir / 'test.json', orient='records')

        # Create a NumPy array file
        np_data = np.array([[1, 2, 3], [4, 5, 6]])
        np.save(self.data_dir / 'test.npy', np_data)

    def test_init_default_dir(self):
        """Test that DataLoader initializes with the default directory if none is provided."""
        with mock.patch('pathlib.Path.exists', return_value=True):
            loader = DataLoader()
            expected_dir = Path(__file__).parent.parent.parent.resolve() / "dataset"
            assert loader.data_dir == expected_dir

    def test_init_creates_dir(self):
        """Test that DataLoader creates the data directory if it doesn't exist."""
        non_existent_dir = self.data_dir / 'non_existent'
        assert not non_existent_dir.exists()

        loader = DataLoader(data_dir=non_existent_dir)
        assert non_existent_dir.exists()

    def test_load_csv(self):
        """Test loading data from a CSV file."""
        df = self.loader.load_csv('test.csv')

        assert isinstance(df, pd.DataFrame)
        assert df.shape == (3, 2)
        assert list(df.columns) == ['A', 'B']
        assert df['A'].tolist() == [1, 2, 3]
        assert df['B'].tolist() == ['x', 'y', 'z']

    def test_load_csv_file_not_found(self):
        """Test that FileNotFoundError is raised when the CSV file doesn't exist."""
        with pytest.raises(FileNotFoundError):
            self.loader.load_csv('non_existent.csv')

    def test_load_json(self):
        """Test loading data from a JSON file."""
        df = self.loader.load_json('test.json')

        assert isinstance(df, pd.DataFrame)
        assert df.shape == (3, 2)
        assert set(df.columns) == {'C', 'D'}

    def test_load_numpy(self):
        """Test loading data from a NumPy file."""
        data = self.loader.load_numpy('test.npy')

        assert isinstance(data, np.ndarray)
        assert data.shape == (2, 3)
        assert np.array_equal(data, np.array([[1, 2, 3], [4, 5, 6]]))

    def test_save_csv(self):
        """Test saving data to a CSV file."""
        df = pd.DataFrame({
            'X': [10, 20, 30],
            'Y': ['p', 'q', 'r']
        })

        output_path = 'test_output.csv'
        self.loader.save_csv(df, output_path)

        # Verify the file was created
        assert (self.data_dir / output_path).exists()

        # Verify the content of the file
        saved_df = pd.read_csv(self.data_dir / output_path)
        assert saved_df.shape == (3, 2)
        assert list(saved_df.columns) == ['X', 'Y']
        assert saved_df['X'].tolist() == [10, 20, 30]
        assert saved_df['Y'].tolist() == ['p', 'q', 'r']
