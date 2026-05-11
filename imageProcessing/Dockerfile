# Use Microsoft's Python development container as base
FROM mcr.microsoft.com/devcontainers/python:3.10

# Set working directory
WORKDIR /app

# Install needed dependencies
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python -m pip install --upgrade pip

# Install needed packages
COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Copy and run server
COPY Trocr.py .
EXPOSE 8080
CMD ["python3", "Trocr.py"]

# # image processing system dependencies
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends \
#     # Packages for image processing
#     tesseract-ocr \
#     libgl1 \
#     libglib2.0-0 \
#     tesseract-ocr-spa \
#     # ADD YOUR PACKAGE HERE
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# # Set working directory
# WORKDIR /workspace