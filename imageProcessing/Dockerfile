# Use Microsoft's Python development container as base
FROM nvidia/cuda:12.9.1-cudnn-runtime-ubuntu22.04

# Set working directory
WORKDIR /app

# Remove interactions during setup
ENV DEBIAN_FRONTEND=noninteractive

# Install needed dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python-is-python3 \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install needed packages
COPY requirements.txt .
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Copy and run server
COPY Trocr.py .
COPY config.py .
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