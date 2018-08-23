add-type -assemblyname system.speech
$talk = new-object System.Speech.Synthesis.SpeechSynthesizer
$talk.Speak("Hello World")
$talk | gm
$talk.GetInstalledVoices()
$talk.GetInstalledVoices().VoiceInfo
$talk.SelectVoice("Microsoft Hazel Desktop")
$talk.Speak("Hello World")
