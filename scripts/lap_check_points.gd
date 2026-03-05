extends Area3D

func _on_body_exited(body: Node3D) -> void:
	Global.is_finishline_crossed =  true
	$"../ui/MarginContainer4/Lap".text = "Lap: " + str(Global.number_of_laps) + "/3"
	
	if Global.number_of_laps > 3 and Global.is_last_lap:
		$"../ui/MarginContainer4/Lap".text = "Lap: " + str(3) + "/3"
		Global.is_game_won = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
