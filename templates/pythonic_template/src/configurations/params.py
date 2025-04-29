from __future__ import annotations

import enum
from dataclasses import dataclass
from typing import Any, Dict, Iterator, List, Literal, Tuple, Type, TypeAlias, TypeVar

import pandas as pd

# Type variable for EnumWithHelpers
T = TypeVar('T', bound='EnumWithHelpers')


class EnumWithHelpers(enum.Enum):
	"""
	EnumWithHelpers extends the basic Enum class with additional helper methods.

	This class adds utility methods for working with enum members, making it easier
	to access members as lists, iterate through them, and convert them to strings.

	Methods:
		members() : Returns a list of all enum members.
		all()     : Returns a list of all enum values (same as members).
		values()  : Returns a list of all enum member values.
		__iter__(): Makes the enum directly iterable,                                      yielding member names.
		__str__() : Custom string representation of enum members. If the value is a tuple,
					returns the first element of the tuple, otherwise returns the value as a string.
	"""
	@classmethod
	def members(cls: Type[T]) -> List[T]:
		return list(cls.__members__.values())

	@classmethod
	def all(cls: Type[T]) -> List[T]:
		return list(cls)

	@classmethod
	def values(cls: Type[T]) -> List[str]:
		return [member.value for member in cls]

	def __iter__(self) -> Iterator[str]:
		return iter(self.__class__.__members__.keys())

	def __str__(self) -> str:
		return str(self.value)


class DatasetNames(EnumWithHelpers):
	"""Example dataset names that might be used in the project."""
	SAMPLE_DATASET_1 = "sample_dataset_1"
	SAMPLE_DATASET_2 = "sample_dataset_2"
	SAMPLE_DATASET_3 = "sample_dataset_3"


class DataModes(EnumWithHelpers):
	"""Data modes for splitting datasets."""
	TRAIN = 'train'
	TEST  = 'test'
	ALL   = 'all'


class SimulationMethods(EnumWithHelpers):
	"""Methods for simulations."""
	RANDOM_STATES = "random_states"
	MULTIPLE_MODELS = "multiple_models"


class OutputModes(EnumWithHelpers):
	"""Output modes for the project."""
	CALCULATE = "calculate"
	LOAD = "load"


class AnalysisTechniques(EnumWithHelpers):
	"""Example techniques for data analysis."""
	STANDARD_DEVIATION = "standard_deviation"
	ENTROPY = "entropy"
	MEAN = "mean"


# Type aliases for improved code readability
VariableID : TypeAlias = str  # Format: 'var_0', 'var_1', etc.
