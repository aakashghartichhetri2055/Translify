import speech_recognition as sr

print("Available microphones:")
print(sr.Microphone.list_microphone_names())