extends Node3D
## Постоянная анимация ленты конвейера.
##
## 1. Крутит текстуру мешей, в имени которых есть [member belt_name_filter]
##    (у модели это все ленты: "Conveyor01Belt_Belt_0*"). Текстура ленты
##    растянута по длине по оси V, поэтому прокручиваем uv1_offset.y.
## 2. Если в сцене есть AnimationPlayer (анимации из GLB), запускает их
##    зацикленными, чтобы они тоже работали постоянно.

## Скорость прокрутки ленты в единицах UV за секунду.
@export var belt_uv_speed: float = 0.35
## Направление движения ленты: 1.0 или -1.0.
@export var belt_direction: float = 1.0
## Подстрока в имени меша, по которой определяется лента (без учёта регистра).
@export var belt_name_filter: String = "belt"

var _belt_materials: Array[BaseMaterial3D] = []


func _ready() -> void:
	_collect_belt_materials()
	_autoplay_animations()


func _process(delta: float) -> void:
	var shift := belt_uv_speed * belt_direction * delta
	if is_zero_approx(shift):
		return
	for material in _belt_materials:
		material.uv1_offset.y = fposmod(material.uv1_offset.y + shift, 1.0)


func _collect_belt_materials() -> void:
	var seen := {}
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance.name.to_lower().contains(belt_name_filter.to_lower()):
			continue
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material := mesh_instance.get_active_material(surface)
			if material is BaseMaterial3D and not seen.has(material):
				seen[material] = true
				_belt_materials.append(material)


func _autoplay_animations() -> void:
	for node in find_children("*", "AnimationPlayer", true, false):
		var player := node as AnimationPlayer
		var animations := player.get_animation_list()
		for animation_name in animations:
			var animation := player.get_animation(animation_name)
			if animation != null and animation.loop_mode == Animation.LOOP_NONE:
				animation.loop_mode = Animation.LOOP_LINEAR
		var autoplay := String(player.autoplay)
		if autoplay != "" and player.has_animation(autoplay):
			player.play(autoplay)
		elif not animations.is_empty():
			player.play(animations[0])
