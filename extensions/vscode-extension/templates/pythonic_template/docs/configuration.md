# Configuration Guide

[← Back to Main README](../README.md) | [Documentation Index](index.md)

This document outlines the configuration process for the Wound Management Interpreter LLM application, focusing on environment setup and variable management.

## Environment Configuration

### Automated Setup (Recommended)

The project includes a dedicated script that handles all environment configuration tasks automatically:

```bash
./scripts/setup_env_variables.sh
```

**What this script does:**
- Creates a `.env` file at the project root based on `setup_config/.env.example`
- Guides you through configuring required API keys
- Sets up optional custom endpoints
- Validates configuration values
- Ensures proper file permissions

### Environment Variables

The following environment variables are managed by the setup script:

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | Authentication key for OpenAI or compatible API services |
| `OPENAI_BASE_URL` | No | Custom endpoint URL (default: OpenAI's standard endpoint) |
| `LOG_LEVEL` | No | Logging verbosity (default: INFO) |
| `PYTHONPATH` | No | Automatically configured by setup scripts |

## Conda Environment Management

### Automated Conda Setup

For development environments, use the provided Conda setup script:

```bash
./scripts/install.sh
```

**What this script does:**
- Creates a Conda environment named `wound_analysis`
- Installs all required dependencies from `setup_config/environment.yml`
- Automatically calls `setup_env_variables.sh` if `.env` doesn't exist
- Provides activation instructions

### Manual Conda Configuration

For advanced users who need custom Conda configurations:

1. Create the environment from specification:
   ```bash
   conda env create -f setup_config/environment.yml
   ```

2. Activate the environment:
   ```bash
   conda activate wound_analysis
   ```

3. Run the environment setup script:
   ```bash
   ./scripts/setup_env_variables.sh
   ```

## Docker Environment Configuration

For containerized deployments, environment variables can be passed to Docker in multiple ways:

1. Using the automated script (recommended):
   ```bash
   ./scripts/setup_env_variables.sh
   ./scripts/run_docker.sh start
   ```

2. Using environment variables at runtime:
   ```bash
   OPENAI_API_KEY=your_key ./scripts/run_docker.sh start
   ```

3. Using a custom .env file location:
   ```bash
   ./scripts/run_docker.sh start --env-file /path/to/custom/.env
   ```

For more details on Docker configuration, see the [Docker Usage Guide](docker_usage.md).

## Troubleshooting

If you encounter configuration issues:

1. Verify your API key is valid and has sufficient permissions
2. Check that your `.env` file exists in the project root
3. Ensure the `.env` file has the correct permissions
4. For Docker deployments, verify the environment variables are being passed correctly

For persistent issues, run the setup script with verbose output:

```bash
./scripts/setup_env_variables.sh --verbose

```
