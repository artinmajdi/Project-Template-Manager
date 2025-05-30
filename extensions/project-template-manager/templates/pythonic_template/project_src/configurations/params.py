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
	"""Dataset names used in the project."""
	TE_KOA = "te_koa"

# Type aliases for improved code readability
VariableID : TypeAlias = str  # Format: 'var_0', 'var_1', etc.
