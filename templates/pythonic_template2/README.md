# TE-KOA (Transcranial Electrical Stimulation for Knee Osteoarthritis)

A data science and machine learning framework for nursing research focused on analyzing the effects of transcranial electrical stimulation on knee osteoarthritis patients. This project provides tools for data loading, preprocessing, visualization, and analysis of clinical trial data.

## Project Overview

The TE-KOA project is designed to facilitate the analysis of clinical research data related to knee osteoarthritis treatments. It includes functionality for:

- Loading and preprocessing clinical trial data from Excel files
- Handling missing data through various imputation methods
- Analyzing treatment groups and their outcomes
- Visualizing data through an interactive dashboard
- Saving processed data for further analysis

## Project Structure

```
te_koa/
├── dataset/                  # Dataset directory containing clinical trial data
├── docs/                     # Documentation files
├── scripts/                  # Utility scripts
├── setup_config/             # Configuration files for setup
│   └── docker/               # Docker configuration files
├── te_koa/                   # Main package directory
│   ├── __init__.py           # Package initialization
│   ├── cli.py                # Command-line interface
│   ├── main.py               # Main entry point
│   ├── configurations/       # Configuration settings
│   │   ├── __init__.py
│   │   ├── params.py         # Parameter definitions
│   │   └── settings.py       # Application settings
│   ├── io/                   # Input/output operations
│   │   ├── __init__.py
│   │   ├── analyze_dictionary.py  # Data dictionary analysis
│   │   ├── analyze_excel_file.py  # Excel file analysis
│   │   └── data_loader.py    # Data loading and preprocessing
│   ├── utils/                # Utility functions
│   │   ├── __init__.py
│   │   └── watchdog.py       # File monitoring utilities
│   └── visualization/        # Data visualization components
│       ├── __init__.py
│       └── app.py            # Streamlit dashboard application
├── tests/                    # Test directory
├── LICENSE.md                # License information
├── MANIFEST.in               # Package manifest
├── README.md                 # This file
├── pyproject.toml            # Project configuration
├── pytest.ini                # PyTest configuration
├── requirements.txt          # Package dependencies
└── setup.py                  # Setup script
```

## Installation

### Prerequisites

- Python 3.10 or higher
- pip (Python package installer)

### Setting up a Virtual Environment

```bash
# Create a virtual environment
python -m venv venv

# Activate the virtual environment
# On Windows
venv\Scripts\activate
# On macOS/Linux
source venv/bin/activate
```

### Installing the Package

```bash
# Install dependencies
pip install -r requirements.txt

# Install the package in development mode
pip install -e .
```

## Usage

### Running the Dashboard

```bash
# Run the Streamlit dashboard
python -m streamlit run te_koa/visualization/app.py
```

Or use the CLI command:

```bash
te_koa-dashboard
```

### Using the Data Loader

```python
from te_koa.io.data_loader import DataLoader

# Create a data loader instance
loader = DataLoader()

# Load the data
data, data_dict = loader.load_data()

# Analyze missing data
missing_report = loader.get_missing_data_report()
print(missing_report[missing_report['Missing Values'] > 0])

# Impute missing values
imputed_data = loader.impute_missing_values(method='knn')

# Get treatment groups
treatment_groups = loader.get_treatment_groups()

# Save processed data
loader.save_processed_data(imputed_data, "processed_data.csv", index=False)
```

## Dashboard Features

The TE-KOA dashboard provides an interactive interface for exploring and analyzing the clinical trial data:

1. **Overview**: Basic information about the dataset, including data types and missing values
2. **Data Explorer**: Tools for exploring the raw data and viewing statistics
3. **Dictionary**: Access to the data dictionary for understanding variable definitions
4. **Visualizations**: Various visualization options including histograms, box plots, scatter plots, and correlation heatmaps
5. **Missing Data & Imputation**: Tools for analyzing and imputing missing data using different methods
6. **Treatment Groups**: Analysis of treatment groups and their outcomes
7. **Save Processed Data**: Options for saving processed data for further analysis

## Contributing

Contributions to the TE-KOA project are welcome. Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
