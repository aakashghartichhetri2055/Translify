FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

RUN python3 -m pip install --no-cache-dir -r requirements.txt

COPY translationEngine.py .
COPY main.py .

EXPOSE 8080

CMD ["python3", "main.py"]