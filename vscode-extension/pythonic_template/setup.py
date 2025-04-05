"""
Setup configuration for the Crowd-Certain package.

This module handles the installation and packaging of the Crowd-Certain library,
which provides tools for crowd-sourced label aggregation with uncertainty estimation
and confidence scoring.
"""

import os
import codecs
from setuptools import find_packages, setup

# Get the absolute path to the directory containing setup.py
here = os.path.abspath(os.path.dirname(__file__))

# Read the README file
with codecs.open(os.path.join(here, "README.md"), encoding="utf-8") as fh:
    long_description = fh.read()

# Read requirements
with codecs.open(os.path.join(here, "requirements.txt"), encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

# Package metadata
PACKAGE_NAME = "project_template"
VERSION = "1.0.0"
AUTHOR = "Your Name"
AUTHOR_EMAIL = "your.email@example.com"
DESCRIPTION = "A template for data science and ML projects"
URL = "https://github.com/username/project_template"
LICENSE = "MIT"

# Classifiers for PyPI
CLASSIFIERS = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Science/Research",
    "License :: OSI Approved :: MIT License",
    "Operating System :: OS Independent",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Topic :: Scientific/Engineering :: Artificial Intelligence",
    "Topic :: Scientific/Engineering :: Medical Science Apps.",
]

# Package data
PACKAGE_DATA = {
    "project_template": [
        "config/*.json",
        "datasets/**/*",
        "utilities/**/*",
    ]
}

# Development requirements
DEV_REQUIREMENTS = [
    "pytest>=8.3.5",
    "black>=25.1.0",
    "isort>=6.0.1",
    "flake8>=7.1.2",
    "mypy>=1.15.0",
    "sphinx>=8.2.3",
    "sphinx-rtd-theme>=3.0.2",
    "sphinx-autodoc-typehints>=3.1.0",
]

setup(
    name=PACKAGE_NAME,
    version=VERSION,
    author=AUTHOR,
    author_email=AUTHOR_EMAIL,
    description=DESCRIPTION,
    long_description=long_description,
    long_description_content_type="text/markdown",
    url=URL,
    license=LICENSE,
    classifiers=CLASSIFIERS,
    python_requires=">=3.10",
    install_requires=requirements,
    extras_require={
        "dev": DEV_REQUIREMENTS,
        "docs": [
            "sphinx>=8.2.3",
            "sphinx-rtd-theme>=3.0.2",
            "sphinx-autodoc-typehints>=3.1.0",
        ],
        "storage": [
            "h5py>=3.7.0",
        ],
    },
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    package_data=PACKAGE_DATA,
    include_package_data=True,
    zip_safe=False,
    entry_points={
        "console_scripts": [
            "project-cli=src.cli:main",
        ],
    },
    keywords=[
        "project-template",
        "data-science",
        "machine-learning",
        "hdf5-storage",
    ],
    project_urls={
        "Bug Tracker": f"{URL}/issues",
        "Documentation": f"{URL}/blob/main/docs/README.md",
        "Source Code": URL,
    },
)
