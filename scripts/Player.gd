extends KinematicBody2D

class_name Player
signal bump

var facing = 'down'
var has_key: bool = false

var last_bump = 'none'
var footstep_offset = 0
const footstep_step = 0.2
const bump_duration = 1
const key_duration = 1

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
    $SoundBump/Timer.wait_time = bump_duration * 0.95
    $KeyJingle/Stop.wait_time = key_duration * 0.95

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

var light_speed = Vector2.ZERO
var light_e_speed = 0

func _physics_process(delta):
    if !$Tween.is_active():
        process_input()
    # animate light
    light_speed += Vector2(randf() * 1.2 - 0.6, randf() * 1.2 - 0.6)
    light_speed = light_speed.clamped(2)
    light_e_speed = clamp(light_e_speed + randf() * 0.2 - 0.09, -0.5, 0.5)
    $Light.energy = min(1, max(0, $Light.energy + light_e_speed * delta))
    $Light.texture_scale = 0.25 + 0.75 * $Light.energy
    $Light.position += light_speed * delta
    $Light.position = $Light.position.clamped(4)

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
        var global_pos = $Ray.global_position + $Ray.cast_to.rotated($Ray.global_rotation)
        if $Ray.get_collider() is TileMap:
            var tilemap = $Ray.get_collider() as TileMap
            tile_id = tilemap.get_cellv(tilemap.world_to_map(global_pos))
        stop_footsteps()
        if last_bump != facing:
            var bump_offset = bumps[tile_id][0]
            var bump_random = bumps[tile_id][1]
            emit_signal("bump", global_pos)
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
    play_keys(false)
    if not $Footsteps.playing:
        $Footsteps.play(footstep_offset)

func stop_footsteps():
    stop_keys()
    if $Footsteps.playing:
        footstep_offset = stepify($Footsteps.get_playback_position(), footstep_step)
        $Footsteps.stop()

func play_bump(position=0):
    stop_bump()
    $SoundBump.pitch_scale = randf() * 0.1 + randf() * 0.2 + 0.85
    $SoundBump.play(position)
    $SoundBump/Timer.start()

func stop_bump(): # called from $SoundBump/Timer.timeout
    play_keys()
    if $SoundBump.playing:
        $SoundBump.stop()

func play_keys(force=true): # called from $KeyJingle/Next.timeout
    if $KeyJingle.playing or not has_key:
        return
    if force or $KeyJingle/Next.is_stopped():
        $KeyJingle.pitch_scale = randf() * 0.2 + 0.8
        $KeyJingle.play((randi() % 6) * key_duration)
        $KeyJingle/Stop.start()

func stop_keys():
    if $KeyJingle.playing:
        $KeyJingle.stop()
    $KeyJingle/Next.wait_time = randf() * 3 + 2
    $KeyJingle/Next.start()