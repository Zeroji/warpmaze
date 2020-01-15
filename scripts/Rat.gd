extends Node2D

onready var squeak: AudioStreamPlayer2D = get_parent().get_node('SoundLayer/Squeak')
var active: bool = true
const squeak_duration = 3

func _ready():
    $SqueakStop.wait_time = squeak_duration

func stfu():
    stop_squeak()
    active = false

func play_squeak():
    if not active or squeak.playing:
        return
    squeak.play((randi() % 8) * squeak_duration)
    $SqueakStop.start()

func stop_squeak():
    if squeak.playing:
        squeak.stop()
    $SqueakNext.wait_time = randf() + 1
    $SqueakNext.start()

func _on_SqueakStop_timeout():
    stop_squeak()

func _on_SqueakNext_timeout():
    play_squeak()
