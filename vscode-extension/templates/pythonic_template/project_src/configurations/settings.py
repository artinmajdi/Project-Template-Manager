import argparse
import json
import os
import pathlib
import sys
from typing import Any, Dict, List, Optional, Union

from pydantic import BaseModel, field_validator

PathNoneType = Union[pathlib.Path, None]

# Default configuration dictionary
DEFAULT_CONFIG_DICT = {
    "project": {
        "name": "my_project",
        "version": "0.1.0",
        "description": "A Python project created from template"
    },
    "data": {
        "input_dir": "dataset/TE-KOA-C - sheet_R01_20250410_mostupdated_only RCT data.xlsx",
        "output_dir": "output",
        "cache_dir": "cache",
        "use_sample_data": False,
        "random_seed": 42
    }
}

# Path to configuration files
CONFIG_PATH = pathlib.Path(__file__).parent


class ProjectSettings(BaseModel):
    """Settings related to the project identity and metadata."""
    name       : str           = "my_project"
    version    : str           = "0.1.0"
    description: str           = "A Python project created from template"
    author     : Optional[str] = None
    repository : Optional[str] = None


class DataSettings(BaseModel):
    """Settings related to data loading and management."""
    input_dir      : pathlib.Path = pathlib.Path('data/input')
    output_dir     : pathlib.Path = pathlib.Path('data/output')
    cache_dir      : pathlib.Path = pathlib.Path('data/cache')
    use_sample_data: bool         = False
    random_seed    : int          = 42

    @field_validator('input_dir', 'output_dir', 'cache_dir', mode='after')
    def make_path_absolute(cls, v: pathlib.Path):
        """Convert relative paths to absolute paths based on project root."""
        return (pathlib.Path(__file__).parents[2] / v).resolve()


class ProcessingSettings(BaseModel):
    """Settings related to data processing and computation."""
    num_workers    : int  = 4
    use_gpu        : bool = False
    debug_mode     : bool = False
    log_level      : str  = "INFO"
    batch_size     : int  = 32
    timeout_seconds: int  = 300

    @field_validator('num_workers', mode='after')
    def limit_workers(cls, v: int):
        """Limit number of workers to available CPU cores."""
        return min(os.cpu_count() or 4, v)


class OutputSettings(BaseModel):
    """Settings related to output and results."""
    save_results         : bool         = True
    export_formats       : List[str]    = ["json", "csv"]
    create_visualizations: bool         = True
    results_dir          : pathlib.Path = pathlib.Path('results')

    @field_validator('export_formats', mode='before')
    def validate_formats(cls, v: Union[List[str], str]):
        """Ensure export formats are in list format."""
        if isinstance(v, str):
            if v.lower() == 'all':
                return ["json", "csv", "pickle", "excel", "html"]
            else:
                return [v.lower()]
        return v

    @field_validator('results_dir', mode='after')
    def make_path_absolute(cls, v: pathlib.Path):
        """Convert relative paths to absolute paths based on project root."""
        return (pathlib.Path(__file__).parents[2] / v).resolve()


class Settings(BaseModel):
    """Main settings class that contains all configuration settings for the application."""
    project   : ProjectSettings
    data      : DataSettings
    processing: ProcessingSettings
    output    : OutputSettings

    class Config:
        use_enum_values = False
        case_sensitive = False
        str_strip_whitespace = True

    def save(self, file_path: Union[str, pathlib.Path]) -> None:
        """
        Save the current configuration to a JSON file.

        Args:
            file_path: Path where the configuration will be saved

        Raises:
            IOError: If the file cannot be written
        """
        # Convert to a dictionary
        config_dict = self.model_dump()

        # Convert Path objects to strings and handle enums
        def convert_values(d):
            for k, v in d.items():
                if isinstance(v, dict):
                    convert_values(v)
                elif isinstance(v, pathlib.Path):
                    d[k] = str(v)
                elif isinstance(v, list) and v and hasattr(v[0], 'value'):
                    # Handle list of enums
                    d[k] = [str(item) for item in v]
                elif hasattr(v, 'value'):
                    # Handle enum values
                    d[k] = str(v)

        convert_values(config_dict)

        # Ensure the directory exists
        file_path = pathlib.Path(file_path)
        file_path.parent.mkdir(parents=True, exist_ok=True)

        # Write the file
        with open(file_path, 'w') as f:
            json.dump(config_dict, f, indent=4)


class ConfigManager:
    """
    Manages configuration loading, validation, and access.

    This class handles finding configuration files, loading settings,
    and providing a centralized way to access application settings.
    """
    @staticmethod
    def find_config_file(config_path: Union[str, pathlib.Path] = CONFIG_PATH / 'config.json', debug: bool = False) -> pathlib.Path:
        """
        Find the config.json file in the project.

        Args:
            config_path: Specific config path to check first (optional)
            debug: Whether to print debug information

        Returns:
            Path to the config.json file
            Note: The returned path may not exist if no config file was found
        """
        # If the provided path is a directory, append the config filename
        config_path = pathlib.Path(config_path)
        if config_path.is_dir():
            config_path = config_path / 'config.json'

        if config_path.exists():
            if debug:
                print(f"Using specified config file at: {config_path}")
            return config_path
        elif debug:
            print(f"Specified config file not found at: {config_path}")

        # Check multiple possible locations for the config file
        possible_locations = [
            # Config directory
            CONFIG_PATH / 'config.json',
            # Current directory
            pathlib.Path.cwd() / 'config.json',
            # Main project directory
            pathlib.Path(__file__).parents[2] / 'config.json',
            # Utils directory
            pathlib.Path(__file__).parent / 'config.json',
            # One level up from current directory
            pathlib.Path.cwd().parent / 'config.json',
            # Two levels up from current directory
            pathlib.Path.cwd().parent.parent / 'config.json'
        ]

        # Check each location and print debug info
        for location in possible_locations:
            if location.exists():
                if debug:
                    print(f"Found config file at: {location}")
                return location
            elif debug:
                print(f"Config file not found at: {location}")

        # If no config file is found, save the default config to the config location
        ConfigManager.revert_to_default_config(debug=debug)

        return CONFIG_PATH / 'config.json'

    @staticmethod
    def revert_to_default_config(config_path: Union[str, pathlib.Path] = CONFIG_PATH / 'config.json', debug: bool = False):
        """
        Create a default config file at the specified location.

        Args:
            config_path: Path where the default config should be saved
            debug: Whether to print debug information
        """
        # Determine the target path for the config file
        config_path = pathlib.Path(config_path)
        if config_path.is_dir():
            config_path = config_path / 'config.json'

        # Ensure the directory exists
        config_path.parent.mkdir(parents=True, exist_ok=True)

        # Copy the default config to the target location
        try:
            with open(config_path, "w") as f:
                json.dump(DEFAULT_CONFIG_DICT, f, indent=4)
            if debug:
                print(f"Successfully saved default config to {config_path}")
        except Exception as e:
            if debug:
                print(f"Error saving default config: {str(e)}")

    @staticmethod
    def get_settings(argv=None, jupyter=True, debug=False) -> Settings:
        """
        Get application settings from command line arguments and/or config file.

        Args:
            argv: Command line arguments (optional)
            jupyter: Whether the function is being called from a Jupyter notebook
            debug: Whether to print debug information

        Returns:
            Settings object with all configuration parameters

        Raises:
            FileNotFoundError: If the config file is not found
        """
        def parse_args() -> dict:
            """
            Parse command line arguments, handling Jupyter notebook special cases.

            Returns:
                Dictionary of parsed arguments
            """
            # If argv is not provided, use sys.argv[1:] to skip the script name
            # For Jupyter notebooks, use an empty list to avoid parsing Jupyter's arguments
            args = [] if jupyter else (argv or sys.argv[1:])

            # Print the arguments for debugging
            if args and debug:
                print(f"Command line arguments: {args}")

            # Initialize the parser
            parser = argparse.ArgumentParser()
            parser.add_argument('--config', type=str, help='Path to config file')
            parser.add_argument('--debug', action='store_true', help='Enable debug mode')

            # Filter out Jupyter-specific arguments
            filtered_argv = [arg for arg in args if not (arg.startswith('-f') or 'jupyter/runtime' in arg.lower())]

            # Parse the arguments
            parsed_args = parser.parse_args(args=filtered_argv)

            # Return only non-None values
            result = {k: v for k, v in vars(parsed_args).items() if v is not None}

            # Print the parsed arguments for debugging
            if result and debug:
                print(f"Parsed arguments: {result}")

            return result

        def get_config(args_dict: Dict[str, Any]) -> Settings:
            """
            Load configuration from a file and update it with command line arguments.

            Args:
                args_dict: Dictionary of command line arguments

            Returns:
                Settings object with configuration parameters
            """
            def load_config_json_file(config_path: pathlib.Path):
                """Load configuration from a JSON file."""
                if debug:
                    print(f"Loading configuration from: {config_path}")

                try:
                    with open(config_path) as f:
                        return json.load(f)
                except json.JSONDecodeError as e:
                    raise ValueError(f"Invalid JSON in config file {config_path}: {e}")
                except Exception as e:
                    raise IOError(f"Error reading config file {config_path}: {e}")

            def update_config(model_class, config_key):
                """Update config data with command line arguments for a specific section."""
                if config_key not in config_data:
                    config_data[config_key] = {}

                for key in model_class.__annotations__:
                    if key in args_dict:
                        config_data[config_key][key] = args_dict[key]

            # Load the config.json file
            config_path = ConfigManager.find_config_file(config_path=args_dict.get('config', CONFIG_PATH / 'config.json'))
            config_data = load_config_json_file(config_path)

            # Validate the config data structure
            required_sections = ['project', 'data', 'processing', 'output']
            missing_sections = [section for section in required_sections if section not in config_data]
            if missing_sections:
                raise ValueError(f"Config file is missing required sections: {', '.join(missing_sections)}")

            # Update each section of the config
            update_config(ProjectSettings, 'project')
            update_config(DataSettings, 'data')
            update_config(ProcessingSettings, 'processing')
            update_config(OutputSettings, 'output')

            # Apply debug mode from command line if specified
            if args_dict.get('debug'):
                config_data['processing']['debug_mode'] = True

            # Create the Settings object
            try:
                return Settings(**config_data)
            except Exception as e:
                raise ValueError(f"Error creating Settings object from config file {config_path}: {e}")

        # Get and return the configuration
        return get_config(args_dict=parse_args())


def main():
    """Test function to demonstrate settings loading."""
    config = ConfigManager.get_settings(debug=True)
    print(f"Project name: {config.project.name}")
    print(f"Data input directory: {config.data.input_dir}")
    print(f"Number of workers: {config.processing.num_workers}")
    print(f"Export formats: {config.output.export_formats}")


if __name__ == '__main__':
    main()


