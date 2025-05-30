"""
Tests for the Knee Osteoarthritis data loader module.

This module contains tests for the DataLoader class that handles loading and preprocessing
of Knee Osteoarthritis dataset.
"""

import os
import tempfile
from pathlib import Path
from unittest import TestCase, mock

import numpy as np
import pandas as pd
import pytest

from src.io.data_loader import DataLoader


class TestDataLoader(TestCase):
    """Test cases for the Knee Osteoarthritis DataLoader class."""

    def setUp(self):
        """Set up test fixtures."""
        # Create a temporary directory for test data
        self.temp_dir = tempfile.TemporaryDirectory()
        self.data_dir = Path(self.temp_dir.name)

        # Create a DataLoader instance with the temp directory
        self.loader = DataLoader(data_dir=str(self.data_dir))

        # Create test data files
        self._create_test_excel_file()

    def tearDown(self):
        """Clean up test fixtures."""
        self.temp_dir.cleanup()

    def _create_test_excel_file(self):
        """Create a test Excel file with data and dictionary sheets."""
        # Create a mock Excel file with both data and dictionary sheets
        # For this we'll create an Excel writer and add two sheets

        excel_path = self.data_dir / "test_koa_data.xlsx"

        with pd.ExcelWriter(excel_path, engine='openpyxl') as writer:
            # Create Sheet1 with sample patient data
            data = pd.DataFrame({
                'PatientID': range(1, 11),
                'Age': [65, 70, 58, 62, 75, 68, 59, 71, 63, 67],
                'Gender': ['F', 'M', 'F', 'M', 'F', 'F', 'M', 'F', 'M', 'F'],
                'tDCS': [1, 0, 1, 0, 1, 0, 1, 0, 1, 0],
                'Medication': [0, 1, 1, 0, 1, 0, 0, 1, 1, 0],
                'WOMAC_pain_baseline': [7.5, 8.2, 6.9, 7.8, 8.5, 7.2, 6.5, 8.0, 7.6, 6.8],
                'WOMAC_pain_6m': [5.2, 7.0, 4.8, 7.5, 5.8, 7.0, 5.0, 6.8, 5.5, 6.5],
                'WOMAC_function_baseline': [28.5, 30.2, 25.9, 29.8, 31.5, 27.2, 24.5, 29.0, 28.6, 26.8],
                'WOMAC_function_6m': [22.2, 28.0, 20.8, 28.5, 23.8, 26.5, 21.0, 26.8, 22.5, 25.5]
            })

            # Add some missing values to test imputation
            data.loc[0, 'WOMAC_pain_6m'] = np.nan
            data.loc[3, 'WOMAC_function_6m'] = np.nan

            # Save to Sheet1
            data.to_excel(writer, sheet_name='Sheet1', index=False)

            # Create dictionary sheet with variable descriptions
            dictionary = pd.DataFrame({
                'Variable': [
                    'PatientID', 'Age', 'Gender', 'tDCS', 'Medication',
                    'WOMAC_pain_baseline', 'WOMAC_pain_6m',
                    'WOMAC_function_baseline', 'WOMAC_function_6m'
                ],
                'Description': [
                    'Unique patient identifier',
                    'Patient age in years',
                    'Patient gender (M/F)',
                    'Transcranial direct current stimulation (1=active, 0=sham)',
                    'Pain medication (1=active, 0=placebo)',
                    'WOMAC pain score at baseline (0-10, higher=worse)',
                    'WOMAC pain score at 6 months (0-10, higher=worse)',
                    'WOMAC function score at baseline (0-68, higher=worse)',
                    'WOMAC function score at 6 months (0-68, higher=worse)'
                ]
            })

            # Save to dictionary sheet
            dictionary.to_excel(writer, sheet_name='dictionary', index=False)

        # Store the path for reference
        self.test_excel_path = excel_path
        self.test_data = data
        self.test_dictionary = dictionary

    def test_init_default_dir(self):
        """Test that DataLoader initializes with the current directory if none is provided."""
        with mock.patch('pathlib.Path.cwd', return_value=Path('/mock/path')):
            test_loader = DataLoader()
            assert test_loader.data_dir == Path('/mock/path')

    def test_init_creates_dir(self):
        """Test that DataLoader creates the data directory if it doesn't exist."""
        non_existent_dir = self.data_dir / 'non_existent'
        assert not non_existent_dir.exists()

        test_loader = DataLoader(data_dir=str(non_existent_dir))
        assert non_existent_dir.exists()

    def test_load_data(self):
        """Test loading data from the Excel file."""
        # Test with default parameters
        filename = self.test_excel_path.name
        data, data_dict = self.loader.load_data(filename=filename)

        # Check that data was loaded correctly
        assert isinstance(data, pd.DataFrame)
        assert isinstance(data_dict, pd.DataFrame)
        assert data.shape[0] == 10  # 10 patients
        assert 'PatientID' in data.columns
        assert 'WOMAC_pain_baseline' in data.columns

        # Check that the data dictionary was loaded
        assert 'Variable' in data_dict.columns
        assert 'Description' in data_dict.columns

        # Check that the data and dictionary were stored correctly
        assert self.loader.data is not None
        assert self.loader.data_dict is not None
        assert self.loader.missing_data_report is not None

    def test_load_data_file_not_found(self):
        """Test that FileNotFoundError is raised when the Excel file doesn't exist."""
        with pytest.raises(FileNotFoundError):
            self.loader.load_data(filename='non_existent.xlsx')

    def test_analyze_missing_data(self):
        """Test analyzing missing data in the dataset."""
        # First load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Check that missing data report is generated
        report = self.loader.missing_data_report
        assert isinstance(report, pd.DataFrame)
        assert 'Missing Values' in report.columns
        assert 'Percentage' in report.columns
        assert 'Data Type' in report.columns

        # Verify missing data is correctly identified
        missing_values = report.loc['WOMAC_pain_6m', 'Missing Values']
        assert missing_values >= 1
        missing_values = report.loc['WOMAC_function_6m', 'Missing Values']
        assert missing_values >= 1

    def test_get_missing_data_report(self):
        """Test getting the missing data report."""
        # When no data is loaded, should return None
        assert self.loader.get_missing_data_report() is None

        # Load data and check report
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        report = self.loader.get_missing_data_report()
        assert isinstance(report, pd.DataFrame)
        assert 'Missing Values' in report.columns

    def test_impute_missing_values_mean(self):
        """Test imputing missing values using mean imputation."""
        # Load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Impute using mean method
        imputed_data = self.loader.impute_missing_values(method='mean')

        # Check that missing values were imputed
        assert not pd.isna(imputed_data['WOMAC_pain_6m']).any()
        assert not pd.isna(imputed_data['WOMAC_function_6m']).any()

        # Verify mean imputation was used correctly
        pain_mean = self.loader.data['WOMAC_pain_6m'].mean()
        function_mean = self.loader.data['WOMAC_function_6m'].mean()

        # Allow for floating point differences
        assert abs(imputed_data.loc[0, 'WOMAC_pain_6m'] - pain_mean) < 0.001
        assert abs(imputed_data.loc[3, 'WOMAC_function_6m'] - function_mean) < 0.001

    def test_impute_missing_values_median(self):
        """Test imputing missing values using median imputation."""
        # Load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Impute using median method
        imputed_data = self.loader.impute_missing_values(method='median')

        # Check that missing values were imputed
        assert not pd.isna(imputed_data['WOMAC_pain_6m']).any()
        assert not pd.isna(imputed_data['WOMAC_function_6m']).any()

        # Verify median imputation was used correctly
        pain_median = self.loader.data['WOMAC_pain_6m'].median()
        function_median = self.loader.data['WOMAC_function_6m'].median()

        # Allow for floating point differences
        assert abs(imputed_data.loc[0, 'WOMAC_pain_6m'] - pain_median) < 0.001
        assert abs(imputed_data.loc[3, 'WOMAC_function_6m'] - function_median) < 0.001

    def test_impute_missing_values_knn(self):
        """Test imputing missing values using KNN imputation."""
        # Load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Impute using KNN method
        imputed_data = self.loader.impute_missing_values(method='knn', knn_neighbors=2)

        # Check that missing values were imputed
        assert not pd.isna(imputed_data['WOMAC_pain_6m']).any()
        assert not pd.isna(imputed_data['WOMAC_function_6m']).any()

        # Can't easily test the KNN imputation values directly, but ensure they're reasonable
        assert 0 <= imputed_data.loc[0, 'WOMAC_pain_6m'] <= 10
        assert 0 <= imputed_data.loc[3, 'WOMAC_function_6m'] <= 68

    def test_impute_missing_values_invalid_method(self):
        """Test imputing missing values with an invalid method."""
        # Load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Try an invalid imputation method
        with mock.patch('logging.Logger.warning') as mock_warning:
            imputed_data = self.loader.impute_missing_values(method='invalid_method')

            # Should log a warning
            mock_warning.assert_called_once()
            # The data should be unchanged
            assert pd.isna(imputed_data.loc[0, 'WOMAC_pain_6m'])
            assert pd.isna(imputed_data.loc[3, 'WOMAC_function_6m'])

    def test_get_treatment_groups(self):
        """Test splitting data into treatment groups."""
        # Load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Get treatment groups
        groups = self.loader.get_treatment_groups()

        # Check that groups were created correctly
        assert isinstance(groups, dict)
        assert set(groups.keys()) == {'Control', 'tDCS Only', 'Medication Only', 'tDCS + Medication'}

        # Check each group has the correct patients
        control_count = sum((self.loader.data['tDCS'] == 0) & (self.loader.data['Medication'] == 0))
        tdcs_only_count = sum((self.loader.data['tDCS'] == 1) & (self.loader.data['Medication'] == 0))
        med_only_count = sum((self.loader.data['tDCS'] == 0) & (self.loader.data['Medication'] == 1))
        combined_count = sum((self.loader.data['tDCS'] == 1) & (self.loader.data['Medication'] == 1))

        assert len(groups['Control']) == control_count
        assert len(groups['tDCS Only']) == tdcs_only_count
        assert len(groups['Medication Only']) == med_only_count
        assert len(groups['tDCS + Medication']) == combined_count

    def test_get_variable_description(self):
        """Test getting variable descriptions from the data dictionary."""
        # Load data
        filename = self.test_excel_path.name
        self.loader.load_data(filename=filename)

        # Test getting a description for a valid variable
        desc = self.loader.get_variable_description('Age')
        assert desc == 'Patient age in years'

        # Test case-insensitive lookup
        desc = self.loader.get_variable_description('age')
        assert desc == 'Patient age in years'

        # Test substring matching
        desc = self.loader.get_variable_description('WOMAC_pain')
        assert 'WOMAC pain score' in desc

        # Test non-existent variable
        with mock.patch('logging.Logger.warning') as mock_warning:
            desc = self.loader.get_variable_description('NonExistentVariable')
            assert desc is None
            mock_warning.assert_called_once()

    def test_save_processed_data(self):
        """Test saving processed data to a CSV file."""
        # Load data
        filename = self.test_excel_path.name
        data, _ = self.loader.load_data(filename=filename)

        # Save to a CSV file
        output_filename = 'processed_koa_data.csv'
        self.loader.save_processed_data(data, output_filename)

        # Check that the file was created
        output_path = self.data_dir / output_filename
        assert output_path.exists()

        # Check the content of the saved file
        saved_data = pd.read_csv(output_path)
        assert saved_data.shape[0] == data.shape[0]
        assert set(saved_data.columns) - {'Unnamed: 0'} == set(data.columns) - {'Unnamed: 0'}

    def test_save_processed_data_with_nonexistent_directory(self):
        """Test saving processed data to a non-existent directory."""
        # Load data
        filename = self.test_excel_path.name
        data, _ = self.loader.load_data(filename=filename)

        # Save to a file in a non-existent subdirectory
        output_filename = 'subdir/processed_koa_data.csv'
        self.loader.save_processed_data(data, output_filename)

        # Check that the file was created (and the directory was created)
        output_path = self.data_dir / output_filename
        assert output_path.exists()

    def test_no_data_loaded(self):
        """Test behavior when no data is loaded."""
        # These methods should return None when no data is loaded
        assert self.loader.get_missing_data_report() is None
        assert self.loader.impute_missing_values() is None
        assert self.loader.get_treatment_groups() is None
        assert self.loader.get_variable_description('Age') is None
