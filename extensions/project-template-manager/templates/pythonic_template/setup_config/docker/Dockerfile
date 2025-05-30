FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file and install dependencies
COPY setup_config/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Install the package in development mode
RUN pip install -e .

# Create directories for data and output if they don't exist
RUN mkdir -p dataset
RUN mkdir -p logs

# Make sure the directories are writable
RUN chmod -R 777 dataset
RUN chmod -R 777 logs

# Expose ports
EXPOSE 8000
EXPOSE 8501

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1

# Command to run the application (can be overridden in docker-compose.yml)
CMD ["python", "-m", "te_koa.main"]
