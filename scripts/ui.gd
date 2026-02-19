extends CanvasLayer

@onready var timer_label: Label = $MarginContainer/TimerLabel
@onready var time_starter_label: Label = $MarginContainer2/TimeStarter

var time := 0.0
var timeStarter := 3
var started := false
var countdown_time := 0.0

func _ready() -> void:
	time_starter_label.text = str(timeStarter)
	process_mode = Node.PROCESS_MODE_ALWAYS  # ← ADD THIS!
	get_tree().paused = true

func _process(delta: float) -> void:
	if Global.is_game_won == false and $YouWin.text != "YOU WON!!!!!!!!":
		$YouWin.text = ""
	elif Global.is_game_won:
		$MarginContainer5/GameOver.text = ""
		$YouWin.text = "YOU WON!!!!!!!!"
		$WinTimer.start()
		Global.is_game_won = false
	# Countdown while paused
	if not started and timeStarter > 0:
		countdown_time += delta
		
		if countdown_time >= 1.0:
			countdown_time -= 1.0
			timeStarter -= 1
			
			if timeStarter > 0:
				time_starter_label.text = str(timeStarter)
			else:
				time_starter_label.text = "GO!"
				await get_tree().create_timer(1).timeout
				get_tree().paused = false
				time_starter_label.text = ""
				started = true
	
	# Game timer
	if started:
		time += delta
		update_label()
	
	# Game over
	if Global.is_game_over == true:
		$MarginContainer5/GameOver.text = "Game Over"
		Global.is_game_over = false
		await get_tree().create_timer(2.0).timeout
		$MarginContainer5/GameOver.text = ""
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Global.is_game_won == true:
		$MarginContainer5/GameOver.text = ""

func update_label() -> void:
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	var milliseconds := int((time - int(time)) * 100)
	timer_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2) + ":" + str(milliseconds).pad_zeros(2)

func set_health(health_amount):
	for child in $MarginContainer3/HBoxContainer.get_children():
		child.queue_free()
	
	for i in health_amount:
		var text_rect = TextureRect.new()
		text_rect.texture = load("res://assets/icons/lighting.png")
		$MarginContainer3/HBoxContainer.add_child(text_rect)

func _on_win_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/you_win.tscn")
	$YouWin.text = ""
