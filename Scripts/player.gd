extends CharacterBody3D

# Movement
const jumpVelocity = 7.0
const baseSpeed = 5.0
@export var sprintModifier = 1.3
@export var crouchModifier = 0.8
@export var airModifier = 1 # Set to 0 to disable airstrafe

@export var smootherMovement:bool = true
const lerpSpeed = 10.0

var direction = Vector3.ZERO

# Head movement
@onready var head = $head
@export var headStandPos = 1.8
@export var headCrouchPos = 1
@export var mouseSensitivity = 0.25

# Collision/crouching
@onready var standing_collider = $standing_collision_shape
@onready var crouching_collider = $crouching_collision_shape
@onready var headbump_raycast = $headbump_raycast

# States
@onready var state = $player_state
var state_list = ["walk", "run", "jump", "crouch"]
var current_state = 0 # Starts on walk state

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	# Filter to motion of the mouse
	if event is InputEventMouseMotion:
		# Rotate body side to side
		rotate_y(deg_to_rad(-event.relative.x * mouseSensitivity))
		# Rotate head only up and down
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		


func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	
	var stateIdx = 0
	
	# Check inputs with priority: jump -> run -> crouch -> walk
	if Input.is_action_pressed("jump") and is_on_floor():
		stateIdx = 2 # set jump
		
	elif Input.is_action_pressed("sprint"):
		stateIdx = 1 # set run
		
	elif Input.is_action_pressed("crouch"):
		stateIdx = 3 # set crouch
		
	else:
		stateIdx = 0 # set walk
		
	
	# If you are crouching, and you cant uncrouch
	if current_state == 3 and not can_uncrouch():
		stateIdx = 3 # Remain crouching
		
	
	# If you are on the middle of a jump
	if current_state == 2:
		stateIdx = 2 # Remain jumping
	
	if(stateIdx != current_state):
		state.send_event(state_list[stateIdx])
		current_state = stateIdx
		


func move_player(speed: float, delta: float):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Check if you want it snappy or smooth
	if smootherMovement:
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed)
		
	else:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	
	move_and_slide()


func can_uncrouch() -> bool:
	return not headbump_raycast.is_colliding()

## STATE FUNCTIONS ##

# On walk we move with base speed
func _on_walk_state_physics_processing(delta):
	move_player(baseSpeed, delta)


# On run we move with sprint speed
func _on_run_state_physics_processing(delta):
	move_player(baseSpeed * sprintModifier, delta)


# At the start of jumping, we set the speed
func _on_jump_state_entered():
	velocity.y = jumpVelocity


# Move player if airstrafe modifier != 0
# Check if we hit the ground and exit jump if we do
func _on_jump_state_physics_processing(delta):
	if(airModifier != 0):
		move_player(baseSpeed * airModifier, delta)
	
	if is_on_floor():
		current_state = 1 # Set state to walk
		state.send_event(state_list[0])


# Swap colliders to crouching
# Turn on head raycast
# Move head to crouch pos
func _on_crouch_state_entered():
	standing_collider.disabled = true
	crouching_collider.disabled = false
	headbump_raycast.enabled = true
	head.position.y = headCrouchPos
	


# On crouch we move the player with crouch speed
func _on_crouch_state_physics_processing(delta):
	move_player(baseSpeed * crouchModifier, delta)
	


# Swap colliders to standing
# Turn off head raycast
# Move head to standing position
func _on_crouch_state_exited():
	standing_collider.disabled = false
	crouching_collider.disabled = true
	headbump_raycast.enabled = false
	head.position.y = headStandPos
	
