extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 4.5
const MAXIMUM_FALL_SPEED = 10

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_vector = Vector3()
var done = false 
var move_action = 0.0 
var y_velocity = 0 
var _heuristic = "model"

var number_of_steps = 0
const MAX_STEPS = 10000
var needs_reset = false 

var reward = 0.0
@onready var second_platform = $"../SecondPlatform"
var best_goal_distance =5000

func shaping_reward():
	
	var shaping_reward =0.0
	
	var goal_distance =0 
	goal_distance = position.distance_to(second_platform.position)
	
	if goal_distance < best_goal_distance:
		shaping_reward += best_goal_distance - goal_distance
		best_goal_distance = goal_distance
		
		shaping_reward /= 1.0
	
	return shaping_reward

func update_reward():
	reward -= 0.01
	reward += shaping_reward()

func get_reward():
	var current_reward = reward
	reward = 0
	return current_reward

func get_move_vector() -> Vector3:
	if done: 
		move_vector = Vector3.ZERO
		return move_vector
		
	return Vector3(
		0,
		0,
		clamp(move_action, -1.0, 1.0)
	)

func reset():
	needs_reset = false 
	number_of_steps = 0
	set_position(Vector3(0, 0.7, 0))
	y_velocity = 0.1 

func _physics_process(delta):
	
	number_of_steps += 1
	if number_of_steps >= MAX_STEPS:
		done = true
		needs_reset = true
		
	if needs_reset:
		reset()
		return 
	
	move_vector *= 0
	move_vector = get_move_vector()
	move_vector = move_vector.rotated(Vector3(0, 1, 0), rotation.y)
	move_vector *= SPEED 
	move_vector.y = y_velocity
	set_velocity(move_vector)
	set_up_direction(Vector3(0, 1, 0))
	move_and_slide()
	
func get_action_space():
	return {
		"move": {
			"size": 1,
			"action_type": "continuous" 
		}
	}
	
func set_action(action):
	move_action = action["move"][0]
	
func get_obs():
	var obs = []
	
	obs.append_array([
		move_vector.x / SPEED,
		move_vector.y / MAXIMUM_FALL_SPEED,
		move_vector.z / SPEED
	])
	
	return {
		"obs": obs
	}

func get_obs_space():
	return {
		"obs": {
			"size": [len(get_obs()["obs"])],
			"space": "box"
		}
	}

func set_heuristic(heuristic):
	self._heuristic = heuristic 

func get_done():
	return done 
	
func set_done_false():
	done = false 
