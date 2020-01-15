extends KinematicBody2D

class_name Player

var facing = 'down'
var last_bump = 'none'
var footstep_offset = 0
const footstep_step = 0.2
const bump_duration = 1

const TILE = 32

const facings = ['down', 'right', 'up', 'left', 'down']
const faces = {'down': 0, 'right': 1, 'up': 2, 'left': 3}
const bumps = [[0, 5], [5, 2]]

var inputs = {
    'down':   Vector2.DOWN,
    'right':  Vector2.RIGHT,
    'up':     Vector2.UP,
    'left':   Vector2.LEFT,
}

func _ready():
    $SoundBump/Timer.wait_time = bump_duration * 0.9

func process_input():
    var direction = 'none'
    for dir in inputs.keys():
        if Input.is_action_pressed(dir):
            direction = dir
    if direction == 'none':
        if $Anim.is_playing():
            $Anim.seek(0, true)
            $Anim.stop()
        stop_footsteps()
        last_bump = 'none' # allow second bump if second input
    else:
        self.move(direction)

func _physics_process(delta):
    if !$Tween.is_active():
        process_input()

func play_anim(name):
    if $Anim.is_playing():
        if $Anim.current_animation == name:
            return
        $Anim.seek(0, true) # reset animation state
    $Anim.play(name)

func move(direction):
    var mv = inputs[direction] * TILE
    var real_mv = mv.rotated(rotation)
    facing = direction
    $Ray.cast_to = mv
    $Ray.force_raycast_update()
    if $Ray.is_colliding():
        var tile_id = 0
        if $Ray.get_collider() is TileMap:
            var tilemap = $Ray.get_collider() as TileMap
            var global_pos = $Ray.global_position + $Ray.cast_to.rotated($Ray.global_rotation)
            tile_id = tilemap.get_cellv(tilemap.world_to_map(global_pos))
        stop_footsteps()
        if last_bump != facing:
            var bump_offset = bumps[tile_id][0]
            var bump_random = bumps[tile_id][1]
            play_bump((randi() % bump_random + bump_offset) * bump_duration)
            last_bump = facing
        play_anim('bump_' + facing)
    else:
        last_bump = 'none'
        play_footsteps()
        $RayLeft.cast_to = (mv * 0.75).rotated(-PI/6)
        $RayLeft.force_raycast_update()
        if $RayLeft.is_colliding():
            warp(real_mv, -1)
            return
        $RayRight.cast_to = (mv * 0.75).rotated(PI/6)
        $RayRight.force_raycast_update()
        if $RayRight.is_colliding():
            warp(real_mv, 1)
            return
        play_anim('walk_' + facing)
        $Tween.interpolate_property(self, 'position', position, position + real_mv, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
        $Tween.start()

func _on_tween_completed(object, key):
    if key == ':position':
        if warping:
            warping = false
            rotation = warp_rot
            $Tween.interpolate_property(object, key, warp_end1, warp_end2, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
            $Tween.start()
        else:
            process_input()

var warping: bool = false
var warp_rot: float
var warp_end1: Vector2
var warp_end2: Vector2

func warp(mv, warp_dir): # +1 for right, -1 for left
    var rot = warp_dir * PI / 2
    var full_mv = mv + mv.rotated(rot)
    warp_end2 = position + full_mv
    warp_end1 = warp_end2 - (mv.rotated(rot) / 2)
    warp_rot = rotation + rot
    warping = true
    $Tween.interpolate_property(self, 'position', position, position + mv / 2, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    $Tween.start()

func play_footsteps():
    if not $Footsteps.playing:
        $Footsteps.play(footstep_offset)

func stop_footsteps():
    if $Footsteps.playing:
        footstep_offset = stepify($Footsteps.get_playback_position(), footstep_step)
        $Footsteps.stop()

func play_bump(position=0):
    stop_bump()
    $SoundBump.pitch_scale = randf() * 0.1 + randf() * 0.2 + 0.85
    $SoundBump.play(position)
    $SoundBump/Timer.start()

func stop_bump(): # called from $SoundBump/Timer.timeout
    if $SoundBump.playing:
        $SoundBump.stop()
