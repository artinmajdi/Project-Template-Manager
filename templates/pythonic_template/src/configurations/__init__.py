"""
Configuration module for the project template.

This module provides configuration classes, parameter definitions, and
settings handling for the template project.
"""

# Import all classes from params module
from src.configurations.params import (
    DataModes,
    DatasetNames,
    EnumWithHelpers,
    OutputModes,
    SimulationMethods,
    AnalysisTechniques
)

# Import settings classes
from src.configurations.settings import (
    ConfigManager,
    Settings,
)

__all__ = [

    # Enums and parameter classes
    'EnumWithHelpers',
    'DatasetNames',
    'DataModes',
    'OutputModes',
    'SimulationMethods',
    'AnalysisTechniques',

    # Settings classes
    'Settings',
    'ConfigManager',
]
