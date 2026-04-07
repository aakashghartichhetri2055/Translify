## Setup
# 1. Docker Installation (Required)
- Follow the steps on the official website base on your system: https://docs.docker.com/get-started/

# 2. Install dev container in Vs code (Required)

# 3. Connect to the container
- Open your repo in VS Code
- Once it detect dockerfile it will have a pop on bottom right corner and then click "reopen in container"
- Alternative: Press F1 and search for "Dev Containers: Reopen in Container"

## Instruction for adding new environment
# 1. Add neccessary packages or depedencies in Dockerfile
# 2. Add neccessary access permission, features, extensions in the devcontainer.json
# 3. Save the changes, press F1 search for "Dev Containers: Rebuild Container" to reload with new changes
# 4. Any tools version should be written in requirement.txt

## TO Run the camera with fastapi
1. go to your directory for example: cd imageprocessing
2. run this command in terminal uvicorn "filename":app --host 0.0.0.0 --port 8000 --reload
3. reple "filename with your file's name for example filename is ocr.py then you put ocr:app
4. then go to your browser http://localhost:8000/
