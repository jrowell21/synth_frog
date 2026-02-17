extends Node

@onready var laser = $laser
# more sounds to add here
	
func play_sound(key, pos=null, db_scale=1, pitch_scale=1):
	var sound = get(key)
	if sound is AudioStreamPlayer or AudioStreamPlayer2D:
		if sound is AudioStreamPlayer2D and pos:
			sound.position = pos
			sound.volume_db = -10*db_scale
			sound.pitch_scale = pitch_scale
		sound.play()
	else:
		print("Sound " + key + " not found!")
