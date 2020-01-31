extends Node2D

class_name Level

func _ready():
    $Player/Light.visible = true
    $CanvasModulate.visible = true
    $Rat/SqueakNext.start()

func _process(delta):
    var view = get_viewport_rect().size
    $SoundLayer.position = (view / 2) + (view / 2 - $Player.position).rotated(-$Player.rotation)
    $SoundLayer.rotation = -$Player.rotation

var player_near_rat: bool = false
var player_has_key: bool = false
var door_unlocked = false

func _on_Rat_Area_body_entered(body):
    if body is Player:
        player_near_rat = true
func _on_Rat_Area_body_exited(body):
    if body is Player:
        player_near_rat = false

func _on_Player_bump(pos):
    if player_has_key or not player_near_rat:
        return
    if (pos - $Rat/Area/CollisionShape2D.global_position).length() < 16:
        $Rat.stfu()
        $SoundLayer/Keys.play()
        $HUD/KeyIcon.visible = true
        $Player.has_key = true
        player_has_key = true
        $Player/KeyJingle/Next.start()

func _on_Player_unlocked():
    $HUD/KeyIcon.visible = false
    door_unlocked = true
