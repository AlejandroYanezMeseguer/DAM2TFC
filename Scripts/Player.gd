extends KinematicBody2D

var PlayerLives = 4
var downdoor = 5
var enter = false
var idle = true
var attack = true
var cooldown = true
var attanim = true
var dead = false
var StopMusic = false
var finalbossMusic = false
var bajarfinalbossMusic = 0.5
var startpos = Vector2()
var previous_player_lives = PlayerLives
var collision_disabled = false
var finalbossLives = 25
var canDash = true
var is_dashing = false
var dash_speed = 460
var dash_duration = 0.055
var dash_timer = 0
var dash_cooldown = 1.5
var dash_cooldown_timer = 0
var moveSpeed = 47
var maxSpeed = 98
var jumpHeight = -272
var gravity = 15
var cooldownAttack = 0.75
var camera_shake_timer = 0
var shake_intensity = 100
var shake_duration = 0.2
var original_camera_position = Vector2() 
var HitPlayer = false
var player
var can_doublejump = true
var doubleJumpItem1 = true
var doubleJumpItem2 = true
var motion = Vector2()
const up = Vector2(0, -1)
onready var camera = $PlayerCamera
onready var sprite = $AnimatedSprite
onready var timerRest = $TimerRest
onready var deadeffect = $deadeffect
onready var timercooldown = $cooldown
onready var deadAnim = $deadAnim
onready var attack_sound = $attack_sound
onready var attack_sound2 = $attack_sound2
onready var jump1_sound = $jump1_sound
onready var jump2_sound = $jump2_sound
onready var dragonslayer_desert_music = $dragonslayer_desert_music
onready var path_of_exile_music = $path_of_exile_music
onready var frostveil_Shrine_music = $frostveil_Shrine_music
onready var crimson_Abyss_Forge_music = $crimson_Abyss_Forge_music
onready var Cursed_Abyssal_Reef_music = $Cursed_Abyssal_Reef_music
onready var FinalBoss = $FinalBos
onready var hitsound = $hit
onready var rest = $rest_sound
onready var title = $AnimatedSprite2
onready var deadtp = $deadtp
onready var deadeff = $"../CanvasLayer/deadteffect"
onready var finalboss = $"../FinalBoss"
onready var door = $"../finalTileMap"
onready var finalBoss = get_node("../FinalBoss")
var enemiesList = [
		"crab", "crab2", "crab3", "crab4", "crab5", "crab6", "crab7", "crab8",
		"bear", "bear2", "bear5", "bear6", "bear7", "bear8",
		"iceMonster", "iceMonster2", "iceMonster3", "iceMonster4", "iceMonster5", "iceMonster6",
		"iceMonster7", "iceMonster8", "iceMonster9", "iceMonster10", "iceMonster11",
		"iceMonsterBoss", "iceMonsterBoss2", "iceMonsterBoss3", "iceMonsterBoss4",
		"bearWizard", "bearWizard2", "bearWizard3",
		"fireWorm", "fireWorm2", "fireWorm3", "fireWorm4",
		"fireWalker", "fireWalker2", "fireWalker3"]
var enemy_nodes = []  

func _ready():
	var deadZones = [$"../DeadZones",$"../IceSpikeDown",$"../IceSpikeUp",$"../IceSpikeRight",$"../IceSpikeLeft",$"../FireSpikeRight",$"../FireSpikeLeft",$"../FireSpikeUp"]
	for deadZone in deadZones:
		deadZone.connect("body_entered", self, "_on_deadZone_body_entered")

	original_camera_position = camera.position
	
	startpos = get_parent().get_node("Startpos").position
	self.position = startpos
	
	sprite.connect("animation_finished", self, "_on_animation_finished")
	initializeTimers()
	
func _physics_process(delta):
	cooldownAttack = cooldownAttack
	motion.y += gravity
	finalBossScene()
	cameraShaker(delta)
	playerLive()
	playerMovement(delta)
	
func finalBossScene():
	if StopMusic:
		crimson_Abyss_Forge_music.volume_db -= 0.5
	if finalbossMusic:
		FinalBoss.volume_db += bajarfinalbossMusic
		door.position.y += downdoor
		if door.position.y >= 0:
			downdoor = 0
		if FinalBoss.volume_db >= -6:
			bajarfinalbossMusic = 0
			
func enemies():
	enemy_nodes.clear()  # Limpiar la lista de nodos antes de añadir nuevos
	for enemie in enemiesList:
		var enemy_node = get_node("../" + enemie)
		if enemy_node:
			enemy_nodes.append(enemy_node)
			enemy_node.respawn()
	StopMusic = false
	finalbossMusic = false
	bajarfinalbossMusic = 0.5
	downdoor = 5
	
func initializeTimers():
	timerRest.wait_time = 2.8
	timerRest.one_shot = true
	timerRest.connect("timeout", self, "rest_timeout")
	
	deadeffect.wait_time = 0.5
	deadeffect.one_shot = true
	deadeffect.connect("timeout", self, "deadeffectF")
	
	deadtp.wait_time = 1.65
	deadtp.one_shot = true
	deadtp.connect("timeout", self, "deadtpF")
	
	timercooldown.wait_time = cooldownAttack
	timercooldown.one_shot = true
	timercooldown.connect("timeout", self, "cooldown_timeout")

func cameraShaker(delta):
	if camera_shake_timer > 0:
		camera_shake_timer -= delta  # Reduce el temporizador cada frame
		var random_offset = Vector2(rand_range(-shake_intensity, shake_intensity), rand_range(-shake_intensity, shake_intensity))
		camera.position = original_camera_position + random_offset  # Mantiene el movimiento de la cámara
	else:
		camera.position = original_camera_position
		
func playerLive():
	if PlayerLives != previous_player_lives:
		match PlayerLives:
			4:
				$"../CanvasLayer/lives".play("4_4")
			3:
				$"../CanvasLayer/lives".play("3_4")
			2:
				$"../CanvasLayer/lives".play("2_4")
			1:
				$"../CanvasLayer/lives".play("1_4")   
		previous_player_lives = PlayerLives 
		
func playerMovement(delta):
	var friction = false
	if HitPlayer == false:
		if is_on_floor() and Input.is_action_pressed("agacharte"):
			$Area2D2/CollisionShape2D.position.y = 17
			$Area2D2/CollisionShape2D.scale.y = 0.7
			idle = false
			moveSpeed = 0
			motion.x = 0
			sprite.play("crouch")
		elif is_on_floor() and Input.is_action_just_released("agacharte"):
			$Area2D2/CollisionShape2D.position.y = 2
			$Area2D2/CollisionShape2D.scale.y = 1
			moveSpeed = 47
			idle = true
		if is_on_floor() and Input.is_action_just_pressed("attack") and idle and attack and cooldown and attanim:
			$Area2D/CollisionShape2D.disabled = false
			cooldown = false
			sprite.play("attack")
			attack = false
			timercooldown.start()
			attack_sound.play()
			attanim = false
		if is_on_floor() and Input.is_action_just_pressed("attack") and idle and attack and cooldown and attanim == false:
			$Area2D/CollisionShape2D.disabled = false
			cooldown = false
			sprite.play("attack 1")
			attack = false
			timercooldown.start()
			attack_sound2.play()
			attanim = true
		elif Input.is_action_pressed("ui_right") and idle and attack:
			sprite.flip_h = false
			$Area2D/CollisionShape2D.position.x = 43.5
			if is_on_floor():
				if sprite != null:
					sprite.play("walk")
				else:
					print("Error: 'sprite' es null en _physics_process")
			motion.x = min(motion.x + moveSpeed, maxSpeed)
		elif Input.is_action_pressed("ui_left") and idle and attack:
			sprite.flip_h = true
			$Area2D/CollisionShape2D.position.x = -43.5
			if is_on_floor():
				if sprite != null:
					sprite.play("walk")
				else:
					print("Error: 'sprite' es null en _physics_process")
			motion.x = max(motion.x - moveSpeed, -maxSpeed)
		elif Input.is_action_just_pressed("ui_accept") and enter and attack and is_on_floor():
			idle = false
			if sprite != null: 
				sprite.play("rest")
				motion.x = 0
				rest.play()
				PlayerLives = 4
				enemies()
				startpos = self.position
			timerRest.start()
		elif idle and attack:
			if sprite != null:
				sprite.play("idle")
			else:
				print("Error: 'sprite' es null en _physics_process")
			friction = true
		if is_on_floor():
			if can_doublejump == false:
				moveSpeed = 47
				maxSpeed = 98
			can_doublejump = true
			if Input.is_action_just_pressed("ui_up") and idle and attack:
				sprite.play("jump")
				motion.y = jumpHeight
				jump1_sound.play()
			if friction == true:
				motion.x = lerp(motion.x, 0, 1)
		else:
			if friction == true:
				motion.x = lerp(motion.x, 0, 0.11)
		if can_doublejump and !is_on_floor() and Input.is_action_just_pressed("ui_up") and doubleJumpItem1 and doubleJumpItem2:
			jump2_sound.play()
			moveSpeed = 62
			maxSpeed = 124
			motion.y = jumpHeight - 28
			can_doublejump = false
			sprite.play("jump")
		if canDash:
			if dash_timer > 0:
				dash_timer -= delta
				motion.x = dash_speed if !sprite.flip_h else -dash_speed
				if dash_timer <= 0:
					is_dashing = false
					dash_cooldown_timer = dash_cooldown
			elif dash_cooldown_timer > 0:
				dash_cooldown_timer -= delta
			elif Input.is_action_just_pressed("shift") and is_on_floor() and !is_dashing and idle and attack:
				$Area2D2/CollisionShape2D.disabled = true
				idle = false
				is_dashing = true
				dash_timer = dash_duration
				sprite.play("dash")
	motion = move_and_slide(motion, up)
	
func hit(damage):
	if !attack:
		PlayerLives -= damage
		hitsound.play()
		shake_camera()
		$AnimatedSprite.modulate = Color(5, 0, 0)  # Cambia el color del sprite a blanco (1, 1, 1)
		var timer = Timer.new()
		timer.wait_time = 0.1  # Duración del color blanco (0.1 segundos)
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", self, "_on_hit_timeout")
		timer.start()
		return
	sprite.stop()
	PlayerLives -= damage
	hitsound.play()
	shake_camera()
	HitPlayer = true
	if !sprite.flip_h:
		motion = Vector2(-100,-250)
	else:
		motion = Vector2(100,-250)
	sprite.play("hurt")
	
func _on_hit_timeout():
	$AnimatedSprite.modulate = Color(1, 1, 1, 1)
	
func updateCooldown(newCool):
	cooldownAttack = newCool
	timercooldown.wait_time = newCool
	timercooldown.stop()  # Detenemos el temporizador
	timercooldown.start()  # Lo volvemos a iniciar
	print(cooldownAttack)
	
func _on_animation_finished():
	if sprite.animation == "hurt":
		HitPlayer = false
		sprite.play("idle")
		
	if sprite.animation == "dash":
		idle = true
		$Area2D2/CollisionShape2D.disabled = false
		
	if sprite.animation == "dead":
		HitPlayer = false
		self.position = startpos
		gravity = 15
		$Area2D2.position.y = 6
		deadeff.play("t")
		enemies()
		door.position.y = -165
		finalBoss.respawn()
		finalbossLives = 25
		
	if sprite.animation == "attack" or sprite.animation == "attack 1":
		$Area2D/CollisionShape2D.disabled = true
		attack = true
		
func deadtpF():
	self.position = startpos
	deadeff.play("t")
	enemies()
		
func deadeffectF():
	deadeff.play("default") 

func rest_timeout():
	idle = true
	
func cooldown_timeout():
	cooldown = true
	
func deadAnimF():
	dead = true

func addCoin():
	var canvasLayer = get_tree().get_root().find_node("CanvasLayer", true, false)
	canvasLayer.handleCoinCollected()

func _on_rest_body_entered(body):
	if body.is_in_group("altar"):
		enter = true
		$"../altar/ECopia".visible = true

func _on_rest_body_exited(body):
	if body.is_in_group("altar"):
		enter = false
		$"../altar/ECopia".visible = false
		
func dead():
	sprite.stop()
	PlayerLives = 4
	sprite.play("dead")
	deadeffect.start()
	$Area2D2.position.y = -5000
	motion = Vector2.ZERO
	gravity = 0
	enemies()

func revive(body):
	if body.get_name() == "Player":
		deadtp.start()
		PlayerLives = 4
		deadeff.play("default")
		
func _on_deadZone_body_entered(body):
	revive(body)

func stop_all_music():
	dragonslayer_desert_music.stop()
	path_of_exile_music.stop()
	frostveil_Shrine_music.stop()
	crimson_Abyss_Forge_music.stop()
	Cursed_Abyssal_Reef_music.stop()
	FinalBoss.stop()
func _on_Area2D4_body_entered(body):
	if body.name == "Player":
		stop_all_music()
		dragonslayer_desert_music.play()
func _on_Area2D5_body_entered(body):
	if body.name == "Player":
		stop_all_music()
		path_of_exile_music.play()
func _on_Area2D6_body_entered(body):
	if body.name == "Player":
		stop_all_music()
		frostveil_Shrine_music.play()
func _on_Area2D7_body_entered(body):
	if body.name == "Player":
		stop_all_music()
		crimson_Abyss_Forge_music.play()
		crimson_Abyss_Forge_music.volume_db = -21
func _on_Area2D8_body_entered(body):
	if body.name == "Player":
		stop_all_music()
		Cursed_Abyssal_Reef_music.play()
		doubleJumpItem2 = false
		moveSpeed = 20
		maxSpeed = 40
		jumpHeight = -123
		gravity = 2
func _on_Area2D8_body_exited(body):
	doubleJumpItem2 = true
	moveSpeed = 47
	maxSpeed = 98
	jumpHeight = -272
	gravity = 15

func shake_camera():
	camera_shake_timer = shake_duration  # Inicia el temporizador
	var random_offset = Vector2(rand_range(-shake_intensity, shake_intensity), rand_range(-shake_intensity, shake_intensity))
	camera.position = original_camera_position + random_offset  # Agita la cámara

func _on_Area2D2_body_entered(body):
	var enemy_damage = {
		"enemie": 1,"enemie1": 1,"enemie2": 1,"enemie3": 2,"enemie4": 1,
		"enemie5": 2,"enemie6": 2,"finalBoss": 1}
	for group in enemy_damage.keys():
		if body.is_in_group(group) and PlayerLives != 0:
			hit(enemy_damage[group])
			break
	if PlayerLives == 0:
		dead()
		$"../CanvasLayer/lives".stop()

func _on_Area2D9_body_entered(body):
	if body.name == "Player":
		Cursed_Abyssal_Reef_music.stop()
		frostveil_Shrine_music.stop()
		path_of_exile_music.stop()
		dragonslayer_desert_music.stop()
		StopMusic = true
		finalBoss.respawnP = false

func _on_Area2D10_body_entered(body):
	if body.name == "Player":
		FinalBoss.play()
		finalbossMusic = true
