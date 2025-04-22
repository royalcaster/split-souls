extends CharacterBody2D

const SPEED = 300.0

var syncPos = Vector2(0, 0) 	# position to synchronize for clients
var syncRot = 0		# rotation to synchronize for clients
@export var bullet :PackedScene 	# scene for bullets (might need later, not important for now)

func _ready():
	# set multiplayer authority (only host or active client can use input)
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _physics_process(delta):
	# only player with authority can move the character
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		
		# aiming gun with mouse, not important for now (included in multiplayer tutorial - might need later when we fight monsters?)
		$GunRotation.look_at(get_viewport().get_mouse_position())

		# movement of the character depending on steering mode (together or separate)
		if(Globals.control_mode_separated):
			separate_steering()
		else: 
			combined_steering()
			
	# player who has not authority: interpolate movement of other player (= to see movements of other player as well+smooth)
	else:
		global_position = global_position.lerp(syncPos, 0.5)
		rotation_degrees = lerpf(rotation_degrees, syncRot, 0.5)

# gunshots, not important for now (might need later)
@rpc("any_peer", "call_local")
func fire():
	var b = bullet.instantiate()
	b.global_position = $GunRotation/BulletSpawn.global_position
	b.rotation_degrees = $GunRotation.rotation_degrees
	get_tree().root.add_child(b)
	
# individual steering - each player moves their own charcter AND sees the movement of the other character
func separate_steering():
	var input_vector = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()

	velocity = input_vector * SPEED
	move_and_slide()

	# synchronize movements (for other player)
	syncPos = global_position
	syncRot = rotation_degrees

	# for shooting => might need later
	#if Input.is_action_just_pressed("Fire"):
		#fire.rpc()

#idea: both players are steering the same character (other one is hidden - this part is missing)
func combined_steering():

	if Globals.combined_direction == null:
		return  # no direction available yet

	velocity = Globals.combined_direction * SPEED
	move_and_slide()

	# synchronize position / rotation 
	syncPos = global_position
	syncRot = rotation_degrees
	
	# send own input to host
	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()

	send_input.rpc_id(1, str(name), input)  # assumption: host 1 is peer & has id 1
	
	
@rpc("any_peer", "call_local")
func send_input(player_id: String, direction: Vector2): # TODO test if this works with two different devices
	Globals.player_inputs[player_id] = direction

	# if there are two inputs => combine them 
	if Globals.player_inputs.size() >= 2:
		var directions = Globals.player_inputs.values()
		var x = 0
		var y = 0

		for dir in directions:
			x += dir.x
			y += dir.y

		# remove inputs in opposite directions (left+right = nothing) - might be modified later, but use for now for simplicity 
		if abs(x) == 2:
			x = 0
		if abs(y) == 2:
			y = 0

		var combined_direction = Vector2(x, y).normalized()

		# set global input
		Globals.combined_direction = combined_direction
