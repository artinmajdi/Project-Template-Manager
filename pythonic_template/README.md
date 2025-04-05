# Project Template

[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/release/python-3120/)
[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

A comprehensive project template for data science, machine learning, and analysis projects. This template provides a standardized structure and setup tools that can be used as a starting point for all your future projects.

<!-- [📚 View Full Documentation](docs/index.md) -->

## Overview

This template offers a standardized project structure with support for various deployment methods (Python virtual environment, Docker, or Conda). It includes configuration management, data loading utilities, visualization tools, and proper logging setup. Use this template to kickstart new projects with good software engineering practices already in place.

## Key Features

- **Standardized Structure**: Well-organized project layout following best practices
- **Multiple Deployment Options**: Support for virtual environments, Docker, and Conda
- **Configuration Management**: Flexible settings with validation via Pydantic
- **Data Processing Tools**: Utilities for loading and processing various data formats
- **Visualization Components**: Built-in Streamlit dashboard template
- **Automated Setup**: Scripts for environment setup and dependency management

### Components

- **Configuration System**: Centralized configuration with validation
- **Data Loaders**: Utilities for various data formats (CSV, Excel, JSON, NumPy)
- **Visualization Dashboard**: Streamlit-based dashboard template
- **Docker Support**: Containerized deployment ready to use
- **Utility Libraries**: Common helper functions for development

## Quick Start

### Prerequisites

- Python 3.10+
- Docker (for containerized deployment)
- Git

### Installation & Setup

Choose the deployment method that best fits your needs:

#### Option 1: Python Virtual Environment

```bash
# 1. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 2. Install dependencies and set up environment
pip install -r setup_config/requirements.txt
pip install -e .
./scripts/setup_env.sh

# 3. Run the application
python src/main.py
```

#### Option 2: Docker Deployment

```bash
# 1. Set up environment variables
./scripts/setup_env.sh

# 2. Start the application in Docker
./scripts/run_docker.sh start

# 3. Access the application at http://localhost:8000
```

#### Option 3: Conda Environment

```bash
# 1. Create and configure the conda environment
./scripts/setup_conda.sh

# 2. Activate the environment
conda activate project_env

# 3. Run the application
python src/main.py
```

## Documentation

- [**Configuration Guide**](docs/configuration.md): Environment variables and configuration options
- [**Docker Usage Guide**](docs/docker_usage.md): Detailed containerization instructions
- [**API Documentation**](docs/api.md): API reference and component documentation
- [**Development Guide**](docs/development.md): Guide for developers

## Project Structure

```
project-template/
├── setup.py                  # Package configuration
├── setup_config/             # Configuration files
│   ├── MANIFEST.in           # Package manifest file
│   ├── pyproject.toml        # Modern Python project metadata
│   ├── pytest.ini            # PyTest configuration
│   └── requirements.txt      # Python dependencies
├── docs/                     # Documentation files
├── setup_config/docker/      # Docker configuration
│   ├── Dockerfile            # Container definition
│   └── docker-compose.yml    # Service orchestration
├── scripts/                  # Utility scripts
│   ├── install.sh            # Installation script
│   ├── run_docker.sh         # Docker management script
│   └── setup_env.sh          # Environment configuration
├── tests/                    # Test suite
├── src/                      # Source code
│   ├── core/                 # Core functionality
│   ├── data/                 # Data handling
│   │   ├── __init__.py
│   │   └── data_loader.py
│   ├── utils/                # Utility modules
│   │   └── config.yaml
│   ├── configurations/       # Configuration system
│   │   ├── __init__.py
│   │   ├── config.json
│   │   ├── params.py
│   │   └── settings.py
│   └── visualization/        # Visualization components
│       └── app.py
├── dataset/                  # Data directory (mounted at runtime)
└── .env                      # Environment variables
```

## License

This project is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/) (CC BY-NC 4.0), which permits non-commercial use with attribution. See the [docs/LICENSE](docs/LICENSE) file for details.

## Using This Template

1. Clone this repository
2. Replace default names in config files and update references
3. Customize the README and documentation
4. Add specific requirements to `requirements.txt`
5. Start building your project!
