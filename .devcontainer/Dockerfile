# Use Microsoft's Python development container as base
FROM mcr.microsoft.com/devcontainers/python:3.10

# image processing system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    # Packages for image processing
    tesseract-ocr \
    libgl1 \
    libglib2.0-0 \
    tesseract-ocr-spa \
    # ADD YOUR PACKAGE HERE
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace
