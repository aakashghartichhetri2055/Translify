# Translation Engine

This component that will facilitate our translation of text, after it has been extracted from image/speech.

# Overview

Our translation engine runs a Hugging Face model locally in order to facilitate translation.

In order to allow our main backend server to receive translations, we run this model in its own local server with FastAPI.

# Engine Details

Current Model: "facebook/nllb-200-distilled-600M"

- [Link to model on Hugging Face](https://huggingface.co/facebook/nllb-200-distilled-600M)

Currently Enabled Languages:

- English
- Spanish
- French

# How To Run

1. Create a new terminal instance, and navigate to the translationEngine/ directory
2. Create a Python virtual environment: `python -m venv venv`
3. Activate the virtual environment: `source venv/bin/activate`
4. Install the required libaries: `pip install -r requirements.txt`
5. Run the server: `uvicorn main:app --port 9000`
   - Make sure that the port number does not conflict with any of the other ports used for the other components of Translify
   - When ever this server is first done on a machine, it will download the model from Hugging Face
      - This step results in additional startup time
      - Something to think about when thinking of deploying the Translify server (main server + other component servers) somewhere

# Tests

```bash
curl -X 'POST' \
  'http://localhost:9000/translate' \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "I am doing pretty well for myself.",
    "sourceLanguage": "en",
    "targetLanguage": "es"
  }'

# Should be something like: "Me estoy haciendo bastante bien para mí mismo."

```

```bash
curl -X 'POST' \
  'http://localhost:9000/translate' \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "I recently started a new job, and it’s been a great experience so far. I’m learning a lot of new skills, especially in project management and team collaboration. I’m excited to see where this opportunity takes me in the future.",
    "sourceLanguage": "en",
    "targetLanguage": "es"
  }'

# Should be something like: "Recientemente he comenzado un nuevo trabajo, y ha sido una gran experiencia hasta ahora. Estoy aprendiendo muchas nuevas habilidades, especialmente en gestión de proyectos y colaboración en equipo. Estoy emocionado de ver hacia dónde me lleva esta oportunidad en el futuro."
```

```bash
curl -X 'POST' \
  'http://localhost:9000/translate' \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "Me gusta mucho el helado.",
    "sourceLanguage": "es",
    "targetLanguage": "en"
  }'

# Should be something like: "I like ice cream a lot."
```

```bash
curl -X 'POST' \
  'http://localhost:9000/translate' \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "Este fin de semana vamos a hacer una fiesta en casa para celebrar mi cumpleaños.",
    "sourceLanguage": "es",
    "targetLanguage": "en"
  }'

# Should be something like: "This weekend we're having a party at home to celebrate my birthday."

```
