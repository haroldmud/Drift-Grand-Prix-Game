extends Node3D

@onready var bg_music :AudioStreamPlayer3D = $BackgroundMusic

func _ready() -> void:
	Global.is_game_won = false
	if bg_music :
		bg_music.stream.loop = true
		bg_music.volume_db = -10
	if bg_music:
		bg_music.play()

func _process(delta: float) -> void:
	pass
