extends Area2D

signal hit
signal healed
signal dead

@export var invincibility_timeout = 3
@export var speed = 400
@export var health_at_start = 3
@export var minimum_health = 1
@export var maximum_health = 3

const DAMAGE = 1

var screen_size
var invincible: bool
var health: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('mobs'): 
		on_mob_entered()
		
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group('hearts'): 
		on_heart_entered(area)
	
func on_mob_entered() -> void:
	if invincible: return
	
	health -= 1
	hit.emit()
	
	if health >= minimum_health:
		make_invincible()
	else: 
		die()
	
func on_heart_entered(heart_node: Area2D) -> void:
	if health == maximum_health:
		return
		
	health += 1
	healed.emit(heart_node)	
	
func die() -> void:
	dead.emit()
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	
func start(pos):
	position = pos
	health = health_at_start
	invincible = false
	show()
	$CollisionShape2D.disabled = false
	
func make_invincible() -> void:
	invincible = true
	
	$CollisionShape2D.set_deferred("disabled", true)
	await flicker()
	$CollisionShape2D.set_deferred("disabled", false)
	
	invincible = false

func flicker() -> void:
	var flicker_time = 0.1
	var elapsed = 0.0

	while elapsed < invincibility_timeout:
		$AnimatedSprite2D.visible = false
		await get_tree().create_timer(flicker_time).timeout
		$AnimatedSprite2D.visible = true
		await get_tree().create_timer(flicker_time).timeout
		elapsed += flicker_time * 2
