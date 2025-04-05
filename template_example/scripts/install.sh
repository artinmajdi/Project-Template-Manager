#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}===========================================================${NC}"
echo -e "${BLUE}          Project Template Installation Script             ${NC}"
echo -e "${BLUE}===========================================================${NC}"
echo ""

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Function to check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Function to determine which Python command to use
get_python_command() {
	if command_exists python3.12; then
		echo "python3.12"
	elif command_exists python3; then
		echo "python3"
	elif command_exists python; then
		echo "python"
	else
		echo -e "${RED}Error: Python is not installed. Please install Python and try again.${NC}" >&2
		exit 1
	fi
}

# Function to determine which mamba command to use
get_mamba_command() {
	if command_exists micromamba; then
		echo "micromamba"
	elif command_exists mamba; then
		echo "mamba"
	else
		echo "" # Return empty string if neither is found
	fi
}

# Function to install uv if it's not available
install_uv() {
    if ! command_exists uv; then
        echo -e "${YELLOW}uv not found. Attempting to install using Homebrew...${NC}"
        if ! command_exists brew; then
            echo -e "${RED}Error: Homebrew ('brew') not found.${NC}" >&2
            echo -e "${YELLOW}Cannot automatically install uv. Please install uv manually.${NC}"
            echo -e "${YELLOW}Falling back to pip for dependency installation.${NC}"
            return 1 # Indicate uv installation failed
        else
            if brew install uv; then
                echo -e "${GREEN}uv installed successfully using Homebrew.${NC}"
            else
                echo -e "${RED}Error: Failed to install uv using Homebrew.${NC}" >&2
                echo -e "${YELLOW}Please try installing uv manually (e.g., using pipx or curl).${NC}"
                echo -e "${YELLOW}Falling back to pip for dependency installation.${NC}"
                return 1 # Indicate uv installation failed
            fi
        fi
    else
        echo -e "${GREEN}uv found.${NC}"
    fi
    return 0 # Indicate uv is available or successfully installed
}

# Function to check Docker installation
check_docker() {
    if ! command_exists docker; then
        echo -e "${RED}Error: Docker is not installed.${NC}" >&2
        echo -e "${YELLOW}Please install Docker from https://docs.docker.com/get-docker/${NC}"
        return 1
    fi

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker daemon is not running.${NC}" >&2
        echo -e "${YELLOW}Please start Docker and try again.${NC}"
        return 1
    fi

    echo -e "${GREEN}Docker is installed and running.${NC}"
    return 0
}

# Function to setup Docker environment
setup_docker() {
    echo -e "${BLUE}Setting up Docker environment...${NC}"

    if ! check_docker; then
        exit 1
    fi

    # Build Docker image
    echo -e "${YELLOW}Building Docker image...${NC}"
    if docker-compose -f "$PROJECT_ROOT/setup_config/docker/docker-compose.yml" build; then
        echo -e "${GREEN}Docker image built successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to build Docker image.${NC}" >&2
        exit 1
    fi
}

# Function to install mamba if it's not available
install_mamba() {
    local mamba_cmd=$(get_mamba_command)
    if [ -z "$mamba_cmd" ]; then
        echo -e "${YELLOW}mamba/micromamba not found.${NC}"
        if command_exists conda; then
            echo -e "${YELLOW}Attempting to install mamba using conda...${NC}"
            if conda install -n base -c conda-forge mamba -y; then
                echo -e "${GREEN}mamba installed successfully using conda into the 'base' environment.${NC}"
                # Re-check the command after installation
                mamba_cmd=$(get_mamba_command)
                if [ -z "$mamba_cmd" ]; then
                    echo -e "${RED}Error: mamba installed but command still not found. Check conda environment activation or PATH.${NC}" >&2
                    return 1
                fi
            else
                echo -e "${RED}Error: Failed to install mamba using conda.${NC}" >&2
                echo -e "${YELLOW}Please try installing mamba or micromamba manually.${NC}" >&2
                echo -e "${YELLOW}See: https://mamba.readthedocs.io/en/latest/installation.html${NC}" >&2
                return 1 # Indicate mamba installation failed
            fi
        else
            echo -e "${RED}Error: conda not found.${NC}" >&2
            echo -e "${YELLOW}Cannot automatically install mamba. Please install mamba or micromamba manually.${NC}" >&2
            echo -e "${YELLOW}See: https://mamba.readthedocs.io/en/latest/installation.html${NC}" >&2
            return 1 # Indicate mamba installation failed
        fi
    else
        echo -e "${GREEN}${mamba_cmd} found.${NC}"
    fi
    return 0 # Indicate mamba is available or successfully installed
}

# Function to create and activate a .venv environment
setup_venv() {
    echo -e "${BLUE}Setting up Python virtual environment...${NC}"
    if [ ! -d "$PROJECT_ROOT/.venv" ]; then
        echo -e "${YELLOW}Creating .venv directory...${NC}"
        $PYTHON_CMD -m venv "$PROJECT_ROOT/.venv"
        # Create a symlink from python to python3 inside the venv
        ln -s "$PROJECT_ROOT/.venv/bin/python3" "$PROJECT_ROOT/.venv/bin/python"
    fi

    # Activate the virtual environment
    source "$PROJECT_ROOT/.venv/bin/activate"

    # Check if setup.py exists
    if [ -f "$PROJECT_ROOT/setup.py" ]; then
        echo -e "${GREEN}Found setup.py, installing package in development mode...${NC}"

        # Install uv if not already installed
        if install_uv; then
            echo -e "${GREEN}Using uv for package installation...${NC}"
            if uv pip install -e .; then
                echo -e "${GREEN}Package installed successfully using uv pip.${NC}"
            else
                echo -e "${RED}Error: Failed to install package using uv pip. Falling back to regular pip...${NC}" >&2
                if pip install -e .; then
                    echo -e "${GREEN}Package installed successfully using pip.${NC}"
                else
                    echo -e "${RED}Error: Failed to install package.${NC}" >&2
                    exit 1
                fi
            fi
        else
            echo -e "${YELLOW}Using regular pip for package installation...${NC}"
            if pip install -e .; then
                echo -e "${GREEN}Package installed successfully using pip.${NC}"
            else
                echo -e "${RED}Error: Failed to install package.${NC}" >&2
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}No setup.py found, installing requirements directly...${NC}"

        # Install uv if not already installed
        if install_uv; then
            echo -e "${GREEN}Using uv for package installation...${NC}"
            if uv pip install -r "$PROJECT_ROOT/setup_config/requirements.txt"; then
                echo -e "${GREEN}Dependencies installed successfully using uv pip.${NC}"
            else
                echo -e "${RED}Error: Failed to install dependencies using uv pip. Falling back to regular pip...${NC}" >&2
                if pip install -r "$PROJECT_ROOT/setup_config/requirements.txt"; then
                    echo -e "${GREEN}Dependencies installed successfully using pip.${NC}"
                else
                    echo -e "${RED}Error: Failed to install dependencies.${NC}" >&2
                    exit 1
                fi
            fi
        else
            echo -e "${YELLOW}Using regular pip for package installation...${NC}"
            if pip install -r "$PROJECT_ROOT/setup_config/requirements.txt"; then
                echo -e "${GREEN}Dependencies installed successfully using pip.${NC}"
            else
                echo -e "${RED}Error: Failed to install dependencies.${NC}" >&2
                exit 1
            fi
        fi
    fi
}

# Function to create and activate a conda environment
setup_conda() {
    echo -e "${BLUE}Setting up conda environment...${NC}"
    if ! command_exists conda; then
        echo -e "${RED}Error: conda is not installed. Please install conda and try again.${NC}" >&2
        exit 1
    fi

    # Check if mamba is installed, install if needed
    if [[ -n "$CONDA_PREFIX" ]]; then
        # Already in a conda environment
        if install_mamba; then
            mamba_cmd=$(get_mamba_command)
            if [ -z "$mamba_cmd" ]; then
                echo -e "${RED}Error: mamba command not found after installation.${NC}" >&2
                exit 1
            fi
        else
            echo -e "${RED}Error: mamba installation failed. Falling back to conda.${NC}" >&2
            mamba_cmd="conda"
        fi
    else
        # Not in a conda environment, activate base first
        echo -e "${YELLOW}Activating base conda environment...${NC}"
        conda activate base
        if install_mamba; then
            mamba_cmd=$(get_mamba_command)
            if [ -z "$mamba_cmd" ]; then
                echo -e "${RED}Error: mamba command not found after installation.${NC}" >&2
                exit 1
            fi
        else
            echo -e "${RED}Error: mamba installation failed. Falling back to conda.${NC}" >&2
            mamba_cmd="conda"
        fi
    fi

    # Set environment name - read name from a config file or prompt user
    ENV_NAME="project_env"

    # Allow the user to input a custom environment name
    echo -e -n "${BLUE}Enter conda environment name [${ENV_NAME}]: ${NC}"
    read custom_env_name
    if [ -n "$custom_env_name" ]; then
        ENV_NAME="$custom_env_name"
    fi

    # Check if environment exists, create if needed
    if ! conda env list | grep -q "^$ENV_NAME "; then
        echo -e "${YELLOW}Creating '$ENV_NAME' conda environment...${NC}"
        $mamba_cmd create -n $ENV_NAME python=$PYTHON_VERSION -y
    fi

    # Install dependencies using mamba/conda
    echo -e "${GREEN}Installing dependencies using ${mamba_cmd}...${NC}"
    # First try to install with conda/mamba directly
    if $mamba_cmd install -n $ENV_NAME -y --file "$PROJECT_ROOT/setup_config/requirements.txt" 2>/dev/null; then
        echo -e "${GREEN}Dependencies installed successfully using ${mamba_cmd}.${NC}"
    else
        # If that fails, activate the environment and use pip
        echo -e "${YELLOW}Could not install all dependencies with ${mamba_cmd}. Trying with pip...${NC}"
        # Activate the conda environment and use pip
        if $mamba_cmd run -n $ENV_NAME pip install -r "$PROJECT_ROOT/setup_config/requirements.txt"; then
            echo -e "${GREEN}Dependencies installed successfully using pip in the conda environment.${NC}"
        else
            echo -e "${RED}Error: Failed to install dependencies.${NC}" >&2
            exit 1
        fi
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${BLUE}Installing project dependencies...${NC}"
    local PYTHON_CMD=$(get_python_command)
    local INSTALLER=""

    # --- Choose Environment ---
    echo -e "${YELLOW}Select environment type:${NC}"
    echo -e "${BLUE}1)${NC} venv (Python virtual environment)"
    echo -e "${BLUE}2)${NC} conda (Conda environment)"
    echo -e "${BLUE}3)${NC} docker (Docker container)"
    echo ""

    while true; do
        echo -e -n "${BLUE}Enter your choice (1-3): ${NC}"
        read choice
        case $choice in
            1)
                ENV_TYPE="venv"
                setup_venv
                INSTALLER="uv"
                break
                ;;
            2)
                ENV_TYPE="conda"
                setup_conda
                INSTALLER="mamba"
                break
                ;;
            3)
                ENV_TYPE="docker"
                setup_docker
                INSTALLER="docker"
                break
                ;;
            *)
                echo -e "${YELLOW}Invalid option. Please enter a number between 1 and 3.${NC}"
                ;;
        esac
    done
}

# --- Main script execution ---

# Verify Python installation and version (reusing existing checks)
PYTHON_CMD=$(get_python_command)
if [ -z "$PYTHON_CMD" ]; then
	exit 1 # Error message already printed by get_python_command
fi

PYTHON_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR_VERSION=$($PYTHON_CMD -c "import sys; print(sys.version_info.major)")

if [ "$PYTHON_MAJOR_VERSION" -lt 3 ]; then
	echo -e "${RED}Error: Python 3.10 or higher is required, but Python $PYTHON_VERSION was found.${NC}"
	echo -e "${YELLOW}Please install Python 3.10 or higher before continuing.${NC}"
	echo -e "${YELLOW}Visit https://www.python.org/downloads/ for installation instructions.${NC}"
	exit 1
fi

PYTHON_MINOR_VERSION=$($PYTHON_CMD -c "import sys; print(sys.version_info.minor)")
if [ "$PYTHON_MAJOR_VERSION" -eq 3 ] && [ "$PYTHON_MINOR_VERSION" -lt 10 ]; then
	echo -e "${RED}Error: Python 3.10 or higher is required, but Python $PYTHON_VERSION was found.${NC}"
	echo -e "${YELLOW}Please install Python 3.10 or higher before continuing.${NC}"
	echo -e "${YELLOW}Visit https://www.python.org/downloads/ for installation instructions.${NC}"
	exit 1
fi
echo -e "${GREEN}Using Python $PYTHON_VERSION${NC}"

# Install dependencies
install_dependencies

# Add activation instructions based on user selection
if [ "$ENV_TYPE" = "venv" ]; then
    echo -e "\n ${BLUE}To activate the virtual environment, run:\n\n    source .venv/bin/activate\n${NC}"
    # Activate the virtual environment for the user
    echo -e "${YELLOW}Activating virtual environment...${NC}"
    source "$PROJECT_ROOT/.venv/bin/activate"
elif [ "$ENV_TYPE" = "conda" ]; then
    echo -e "\n ${BLUE}To activate the conda environment, run:\n\n    conda activate $ENV_NAME\n${NC}"
elif [ "$ENV_TYPE" = "docker" ]; then
    echo -e "\n ${BLUE}To run the application in Docker, use:\n\n    docker-compose -f setup_config/docker/docker-compose.yml up\n${NC}"
fi

# Add instructions for running the application
if [ "$ENV_TYPE" = "docker" ]; then
    echo -e "\n${BLUE}The application will be available at:${NC}"
    echo -e "${GREEN}    http://localhost:8000${NC}\n"
else
    echo -e "\n${BLUE}To run the application, activate your environment and run:${NC}"
    if [ -f "$PROJECT_ROOT/setup.py" ]; then
        echo -e "${GREEN}    python -m src.main${NC}\n"
    else
        echo -e "${GREEN}    python src/main.py${NC}\n"
    fi
fi

echo ""
echo -e "${GREEN}===========================================================${NC}"
echo -e "${GREEN}        Installation completed successfully!               ${NC}"
echo -e "${GREEN}===========================================================${NC}"

exit 0
