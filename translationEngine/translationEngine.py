"""
A class defining our translation engine
"""
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch

class TranslationEngine:
   def __init__(self, modelName):
      self.modelName = modelName

      self.tokenizer = AutoTokenizer.from_pretrained(self.modelName)
      self.model = AutoModelForSeq2SeqLM.from_pretrained(self.modelName)

      self.device = "mps" if torch.backends.mps.is_available() else "cpu"
      self.model = self.model.to(self.device)

      # A dictionary mapping the standard langauge codes to the codes used by Facebook's model
      self.facebookLanguageCodes = {
         "es": "spa_Latn",
         "en": "eng_Latn",
         "fr": "fra_Latn"
      }

   def translate(self, text, srcLang, tgtLang):
      # Get the correct langauge codes and make sure that they are supported
      source = self.facebookLanguageCodes.get(srcLang, None)
      target = self.facebookLanguageCodes.get(tgtLang, None)

      if source is None or target is None:
         raise ValueError("Unsupported Language")
      
      # Set the tokenizer to the source language
      self.tokenizer.src_lang = source

      # Get the output from the model
      inputs = self.tokenizer(text, return_tensors = "pt").to(self.device)
      outputs = self.model.generate(
         **inputs,
         forced_bos_token_id = self.tokenizer.convert_tokens_to_ids(target),
         max_length=200
      )

      # Decode the output
      result = self.tokenizer.decode(outputs[0], skip_special_tokens = True)

      return result

def main():
   print("translationEngine.py ran as its own file")

if __name__ == '__main__':
   main()