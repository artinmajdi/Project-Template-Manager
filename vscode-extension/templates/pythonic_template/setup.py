"""
Setup configuration for the TE-KOA package.

This module handles the installation and packaging of the TE-KOA library,
which provides tools for data science and machine learning in nursing research
and healthcare applications.
"""

from setuptools import setup, find_packages
import os
import pathlib
import codecs

# # Get the current directory (project root directory)
# project_root = pathlib.Path(__file__).parent.absolute()

# # Read requirements from requirements.txt or use hardcoded list if file not found
# try:
#     with open(os.path.join(project_root, 'requirements.txt')) as f:
#         requirements = f.read().splitlines()
# except FileNotFoundError:
#     # Fallback requirements list if requirements.txt is not available (e.g., during build from sdist)
#     requirements = [
#         "pandas>=2.0.0",
#         "numpy>=1.24.0",
#         "scipy>=1.11.0",
#         "python-docx>=0.8.11",
#         "python-dotenv>=0.19.0",
#         "streamlit>=1.30.0",
#         "plotly>=5.18.0",
#         "pillow>=10.0.0",
#         "pydantic>=2.0.0",
#         "langchain-core>=0.1.0",
#         "langchain-openai>=0.0.1",
#         "openai>=0.27.0",
#         "openpyxl>=3.1.0",
#         "protobuf>=3.20.0",
#         "sacremoses",
#         "watchdog"
#     ]

# # Read long description from README.md
# with open(os.path.join(project_root, 'README.md'), 'r', encoding='utf-8') as f:
#     long_description = f.read()


# Get the absolute path to the directory containing setup.py
here = os.path.abspath(os.path.dirname(__file__))

# Read the README file
with codecs.open(os.path.join(here, "README.md"), encoding="utf-8") as fh:
    long_description = fh.read()

# Read requirements
with codecs.open(os.path.join(here, "requirements.txt"), encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

# Package metadata
PACKAGE_NAME = "te_koa"
VERSION      = "0.1.0"
AUTHOR       = "Artin Majdi"
AUTHOR_EMAIL = "msm2024@gmail.com"
DESCRIPTION  = "A data science and machine learning framework for nursing research"
URL          = "https://github.com/artinmajdi/te_koa"
LICENSE      = "MIT"

# Classifiers for PyPI
CLASSIFIERS = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Science/Research",
    "Intended Audience :: Healthcare Industry",
    "Operating System :: OS Independent",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Topic :: Scientific/Engineering :: Artificial Intelligence",
    "Topic :: Scientific/Engineering :: Medical Science Apps.",
    "Topic :: Scientific/Engineering :: Information Analysis",
]


setup(
    name=PACKAGE_NAME,
    version=VERSION,
    description=DESCRIPTION,
    long_description=long_description,
    long_description_content_type="text/markdown",
    author=AUTHOR,
    author_email=AUTHOR_EMAIL,
    url=URL,
    packages=find_packages(),
    include_package_data=True,
    python_requires=">=3.10",
    install_requires=requirements,
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Healthcare Industry",
        "License :: Other/Proprietary License",  # CC BY-NC 4.0 isn't a standard classifier
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Scientific/Engineering :: Medical Science Apps.",
    ],
    entry_points={
        'console_scripts': [
            'te_koa=te_koa.main:main',
            'te_koa-dashboard=te_koa.cli:run_dashboard',
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
