"""Streamlit runtime configuration for Python path.
This file is automatically loaded by Streamlit when the app starts.
It ensures proper module imports and environment setup for the application.
"""
import os
import sys
import pathlib
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('project_src')

try:
    # Add the project root to the Python path
    root_path = pathlib.Path(__file__).parent.parent.absolute()
    sys.path.insert(0, str(root_path))
    logger.info(f"Added {root_path} to Python path")

    # Setup module reloading for better development experience
    import importlib
    def reload_modules():
        """Force reload of project modules to ensure latest changes are used."""
        for module_name in list(sys.modules.keys()):
            if module_name.startswith('project_src'):
                try:
                    importlib.reload(sys.modules[module_name])
                except:
                    pass

    # Call this function to reload modules on startup
    reload_modules()

    # Load environment variables from .env file if not in Streamlit Cloud
    env_file = root_path / '.env'
    if env_file.exists():
        load_dotenv(dotenv_path=env_file)
        logger.info(f"Loaded environment variables from {env_file}")
    else:
        logger.info("No .env file found, using environment or secrets")

    # Detect deployment environment
    is_streamlit_cloud = os.environ.get('IS_STREAMLIT_CLOUD', False)
    logger.info(f"Running in Streamlit Cloud: {is_streamlit_cloud}")

    # Check for required directories
    data_dir = root_path / 'dataset'
    if not data_dir.exists():
        logger.warning(f"Data directory not found: {data_dir}")
        # Create data directory if it doesn't exist
        data_dir.mkdir(exist_ok=True)
        logger.info(f"Created data directory: {data_dir}")

except Exception as e:
    logger.error(f"Error in runtime configuration: {str(e)}")
    # Continue execution even if there's an error
    pass
