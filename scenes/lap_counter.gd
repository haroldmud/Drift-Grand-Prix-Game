extends Area3D

var number_of_laps := 1

func _process(_delta: float) -> void:
	Global.number_of_laps = number_of_laps
	if number_of_laps >= 3:
		Global.is_last_lap = true
 

func _on_body_exited(body: Node3D) -> void:
	if Global.is_finishline_crossed:
		number_of_laps += 1
		Global.is_finishline_crossed =  false
