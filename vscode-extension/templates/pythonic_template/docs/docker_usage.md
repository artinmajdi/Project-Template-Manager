# Docker Usage Guide

[← Back to Main README](../README.md) | [Documentation Index](index.md)

This guide provides comprehensive instructions for deploying the Wound Management Interpreter LLM application using Docker containers. Docker provides a consistent environment for running the application regardless of your local setup.

## Prerequisites

Before starting, ensure you have:

- Docker and Docker Compose installed on your system
- Access to required API keys (particularly OpenAI)
- Sufficient disk space for Docker images and volumes
- The project code downloaded to your local machine

## Quick Start

The project includes a dedicated script that handles all Docker operations:

```bash
# Set up environment variables first
./scripts/setup_env_variables.sh

# Start the application
./scripts/run_docker.sh start
```

After running these commands, the Streamlit interface will be available at http://localhost:8501.

## Docker Management Script

The `run_docker.sh` script provides a convenient interface for managing Docker containers:

```bash
./scripts/run_docker.sh [command] [options]
```

### Available Commands

| Command | Description |
|---------|-------------|
| `start` | Start the application containers |
| `stop` | Stop running containers |
| `restart` | Restart containers |
| `logs` | View container logs |
| `build` | Rebuild containers |
| `cli` | Run the command line interface |
| `verify` | Run dataset verification |

### Options

| Option | Description |
|--------|-------------|
| `--env-file PATH` | Specify a custom .env file location |
| `--build` | Force rebuild of containers |
| `--detach` | Run containers in detached mode |
| `--no-detach` | Run containers in foreground |
| `--no-cache` | Build without using cache |

## Docker Profiles

The docker-compose.yml configuration includes several profiles for different use cases:

### Main Web Application (Default)

Runs the Streamlit dashboard for interactive analysis:

```bash
./scripts/run_docker.sh start
```

This will launch the web interface for interactive wound analysis.

### Command Line Interface (CLI)

For processing specific patient records via command line:

```bash
# Run analysis for patient with specific record ID (e.g., 43)
./scripts/run_docker.sh cli 43

# Run with default record ID if none specified
./scripts/run_docker.sh cli
```

The CLI mode is useful for batch processing or integrating with other systems. You can simply append the record ID as a parameter after the `cli` command. If no record ID is provided, the system will use the default record ID specified in the docker-compose.yml file (currently set to 41).

### Dataset Verification

Verifies the dataset integrity and structure:

```bash
# Run dataset verification
./scripts/run_docker.sh verify
```

This profile checks if your dataset adheres to the expected schema and reports any issues.

## Environment Variables

The Docker deployment uses environment variables for configuration. These can be provided in several ways:

### Method 1: Using the Setup Script (Recommended)

```bash
./scripts/setup_env_variables.sh
./scripts/run_docker.sh start
```

This interactive script will guide you through setting up required variables.

### Method 2: Using Environment Variables at Runtime

```bash
OPENAI_API_KEY=your_key ./scripts/run_docker.sh start
```

This method allows for quick testing with temporary values.

### Method 3: Using a Custom .env File

```bash
./scripts/run_docker.sh start --env-file /path/to/custom/.env
```

Your .env file should include at minimum:

```
OPENAI_API_KEY=your_openai_api_key
MODEL_NAME=gpt-4-turbo-preview  # or another compatible model
```

## Volume Mounts

The Docker configuration includes the following volume mounts:

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./dataset` | `/app/dataset` | Data storage |
| `./setup_config` | `/app/setup_config` | Configuration files |
| `./{output_dir}` | `/app/output` | Analysis results |

### Custom Dataset Location

You can specify a custom dataset location:

```bash
DATASET_PATH=/path/to/custom/dataset ./scripts/run_docker.sh start
```

This allows flexibility in where your data is stored while maintaining the application's expected structure.

## Advanced Usage

### Viewing Application Logs

```bash
./scripts/run_docker.sh logs
```

Add `-f` to follow logs in real-time (this is actually the default in the script).

### Custom Docker Compose Configuration

For advanced users who need to modify the Docker Compose configuration:

1. Create a custom docker-compose override file
2. Use the Docker Compose directly with your custom file:

```bash
docker compose -f docker/docker-compose.yml -f /path/to/docker-compose.custom.yml --env-file .env up -d
```

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Permission errors | Ensure proper permissions on mounted volumes: `chmod -R 755 ./dataset ./setup_config` |
| Missing environment variables | Verify .env file exists and contains required variables |
| Port conflicts | Check if port 8501 is already in use: `lsof -i :8501` |
| Container fails to start | Check logs with `./scripts/run_docker.sh logs` |
| API rate limits | Implement delay between API calls or upgrade your OpenAI plan |
| Out of memory errors | Increase Docker resources or optimize batch size |

### Diagnostic Commands

```bash
# View detailed logs
./scripts/run_docker.sh logs

# Rebuild containers from scratch
docker compose -f docker/docker-compose.yml --env-file .env build --no-cache

# Check Docker system resources
docker system df

# Remove unused Docker resources
docker system prune
```

## Performance Optimization

For production deployments, consider the following optimizations:

1. Increase container resources in docker-compose.yml:
   ```yaml
   services:
     app:
       deploy:
         resources:
           limits:
             cpus: '2'
             memory: 4G
   ```

2. Use a production-grade web server in front of Streamlit (like Nginx)
3. Configure appropriate cache settings
4. Use a dedicated database for large datasets instead of CSV files
5. Implement a queuing system for batch processing

## Security Considerations

- Never commit .env files containing API keys
- Use the `--env-file` option to keep sensitive data outside the project directory
- Consider using Docker secrets for production deployments
- Restrict network access to the Docker container in production
- Regularly update base images and dependencies
- Run containers with non-root users when possible

## Continuous Integration/Deployment

For teams looking to implement CI/CD:

1. Use Docker Hub or GitHub Container Registry to store images
2. Include Docker testing in your CI pipeline
3. Implement automatic image building on commits to main branch
4. Use Docker Compose's environment variable substitution for different environments
