extends CharacterBody3D

# Movement
const jumpVelocity = 7.0
const baseSpeed = 5.0
@export var sprintModifier = 1.3

@export var smootherMovement:bool = true
const lerpSpeed = 10.0

# Head movement
@onready var head = $head
@export var mouseSensitivity = 0.25

# Random
var direction = Vector3.ZERO

#@onready var standing_collision_shape = $standing_collision_shape

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
	# Reset speed to base
	var currentSpeed = baseSpeed
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor(): #and not isCrouched:
		velocity.y = jumpVelocity
		
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if Input.is_action_pressed("sprint"):
		currentSpeed *= sprintModifier
		
	
	# Check if you want it snappy or smooth
	if smootherMovement:
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpSpeed)
		
	else:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	
	# Set the speed
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)
	
	move_and_slide()
