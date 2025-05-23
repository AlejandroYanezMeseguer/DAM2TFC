extends Area2D

onready var ui = get_node("../ControlCanvas/CanvasLayer")
onready var player = get_node("../Player")
var text = 0
var enter = false
onready var next = $"../ControlCanvas/CanvasLayer/nextLabel"
var target_scales = {}
var lerp_speed = 15.0

# Variables para el texto letra por letra
var current_text = ""
var current_index = 0
var is_typing = false
var dialog_texts = [
	"Hehehe, you must be the little rat they picked to save us from the volcano. Well, for a small price in gold, I can sell you some totally not stolen items... hehehe.",

]
var timer = null  # Asegúrate de añadir un Timer a la escena y conectarlo
onready var talking_sound = $"../ControlCanvas/CanvasLayer/Talking"  # Asegúrate de tener este nodo de audio

func _ready():
	$AnimatedSprite.play("idle")
	create_timer()  # Creamos el Timer dinámicamente

# Crear el Timer dinámicamente
func create_timer():
	timer = Timer.new()  # Creamos una nueva instancia de Timer
	timer.wait_time = 0.08  # Velocidad del texto (ajusta según necesites)
	timer.connect("timeout", self, "_on_Timer_timeout")  # Conectamos la señal timeout
	add_child(timer)

func _on_TraderCave_body_entered(body):
	if body.name == "Player":
		enter = true
		$ECopia.visible = true

func _on_TraderCave_body_exited(body):
	if body.name == "Player":
		enter = false
		$ECopia.visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelBible".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelNeckles".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelSword".visible = false
		player.cooldown = true
		reset_dialog()

func _process(delta):
	# Aplicar la interpolación de escala a los botones
	for button in $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2".get_children():
		if button.name in target_scales:
			button.rect_scale = lerp(
				button.rect_scale,
				target_scales[button.name],
				lerp_speed * delta
			)
	
	# Lógica del diálogo
	if Input.is_action_just_released("ui_accept") and enter:
		if not is_typing:
			player.cooldown = false
			text += 1
			next.play()
			start_dialog()
		else:
			# Si el jugador presiona "Aceptar" mientras se escribe, completar el texto
			complete_text()

	update_dialog_visibility()

# Iniciar el diálogo
func start_dialog():
	if text <= dialog_texts.size():
		current_text = ""
		current_index = 0
		is_typing = true
		timer.start()

# Completar el texto actual
func complete_text():
	var active_label = $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTrader1"
	current_text = dialog_texts[text - 1]
	active_label.bbcode_text = current_text
	is_typing = false
	timer.stop()

# Actualizar la visibilidad de los diálogos
func update_dialog_visibility():
	if text == 1:
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader".visible = true
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTrader1".visible = true
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTrader1".bbcode_text = current_text
	elif text == 2:
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTrader1".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2".visible = true
	elif text == 3:
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelBible".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelNeckles".visible = false
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelSword".visible = false
		text = 0

	if not enter:
		reset_dialog()

# Reiniciar el diálogo
func reset_dialog():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTrader1".visible = false
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2".visible = false
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader".visible = false
	text = 0
	current_text = ""
	current_index = 0
	is_typing = false
	timer.stop()

# Lógica del Timer para mostrar letra por letra
func _on_Timer_timeout():
	var active_label = $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTrader1"
	if active_label and current_index < dialog_texts[text - 1].length():
		# Obtenemos el siguiente grupo de 3 caracteres
		var next_group = dialog_texts[text - 1].substr(current_index, 3)
		
		# Buscar signos de puntuación dentro del grupo
		var pause_index = -1  # Índice donde se debe hacer la pausa
		for i in range(next_group.length()):
			if next_group[i] in [".", ";", ":", "!", "?"]:
				pause_index = i  # Guardamos la posición del signo de puntuación
				break  # Salimos del bucle al encontrar el primer signo

		# Si se encontró un signo de puntuación, ajustamos el grupo
		if pause_index != -1:
			next_group = next_group.substr(0, pause_index + 1)  # Cortamos el grupo hasta el signo
			current_index += pause_index + 1  # Avanzamos el índice hasta después del signo
		else:
			current_index += 3  # Si no hay signos, avanzamos 3 caracteres

		# Añadimos el grupo al texto actual
		current_text += next_group
		active_label.bbcode_text = current_text

		# Reproducir el sonido con un pitch aleatorio
		var pitch_values = [1.6,1.8, 2]  # Valores predefinidos
		talking_sound.pitch_scale = pitch_values[randi() % pitch_values.size()]  # Selecciona un valor aleatorio
		talking_sound.play()

		# Si se encontró un signo de puntuación, hacemos una pausa
		if pause_index != -1:
			timer.stop()  # Detener el Timer temporalmente
			yield(get_tree().create_timer(0.2), "timeout")  # Pausa de 0.5 segundos
			timer.start()  # Reanudar el Timer
	else:
		is_typing = false
		timer.stop()

#func _on_Button_button_down():
#	if ui.coins >= 25 and not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button".disabled:
#		target_scales["Button"] = Vector2(0.22, 0.20)
#
#func _on_Button2_button_down():
#	if ui.coins >= 15 and not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button2".disabled:
#		target_scales["Button2"] = Vector2(0.4, 0.4)
#
#func _on_Button3_button_down():
#	if ui.coins >= 15 and not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button3".disabled:
#		target_scales["Button3"] = Vector2(0.4, 0.4)

func _on_Button_mouse_entered():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = true
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelBible".visible = true
	if not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button".disabled:
		target_scales["Button"] = Vector2(0.26, 0.23)
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/buttonHovered".play()
		
func _on_Button_mouse_exited():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = false
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelBible".visible = false
	if not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button".disabled:
		target_scales["Button"] = Vector2(0.25, 0.22)

func _on_Button2_mouse_entered():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = true
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelNeckles".visible = true
	if not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button2".disabled:
		target_scales["Button2"] = Vector2(0.46, 0.46)
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/buttonHovered".play()

func _on_Button2_mouse_exited():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = false
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelNeckles".visible = false
	if not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button2".disabled:
		target_scales["Button2"] = Vector2(0.44, 0.44)

func _on_Button3_mouse_entered():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = true
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelSword".visible = true
	if not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button3".disabled:
		target_scales["Button3"] = Vector2(0.46, 0.46)
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/buttonHovered".play()

func _on_Button3_mouse_exited():
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2".visible = false
	$"../ControlCanvas/CanvasLayer/PanelSnowTrader2/LabelSword".visible = false
	if not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button3".disabled:
		target_scales["Button3"] = Vector2(0.44, 0.44)


func _on_Button_pressed():
	if ui.coins >= 25 and not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button".disabled:
		target_scales["Button"] = Vector2(0.22, 0.20)
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button".disabled = true
		ui.coins -= 25
		$"../ControlCanvas/CanvasLayer/Book06c".visible = true
		player.doubleJumpItem1 = true
		print("presed")
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/buttonPressed".play()

func _on_Button2_pressed():
	if ui.coins >= 15 and not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button2".disabled:
		target_scales["Button2"] = Vector2(0.4, 0.4)
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button2".disabled = true
		ui.coins -= 15
		$"../ControlCanvas/CanvasLayer/Necklace02d".visible = true
		player.canDash = true
		print("presed")
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/buttonPressed".play()


func _on_Button3_pressed():
	if ui.coins >= 15 and not $"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button3".disabled:
		target_scales["Button3"] = Vector2(0.4, 0.4)
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/SnowTader2/Button3".disabled = true
		ui.coins -= 15
		$"../ControlCanvas/CanvasLayer/Item06".visible = true
		player.updateCooldown(0.35)
		print("presed")
		$"../ControlCanvas/CanvasLayer/PanelSnowTrader/buttonPressed".play()
