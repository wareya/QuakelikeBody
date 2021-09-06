extends KinematicBody

class_name QuakelikeBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.



class CollisionData:
    var collider
    var collider_id
    var collider_metadata
    var collider_shape
    var collider_shape_index
    var collider_velocity
    var local_shape
    var normal
    var position
    var remainder
    var travel

func wrap_move_and_collide(motion, infinite_inertia = true, test_only = false):
    var collision = move_and_collide(motion, infinite_inertia, test_only)
    #print("collision dot:")
    #print()
    #var dot = 
    if collision == null or motion.dot(collision.normal) >= 0.0:
        return null
    var ret = CollisionData.new()
    ret.collider = collision.collider
    ret.collider_id = collision.collider_id
    ret.collider_metadata = collision.collider_metadata
    ret.collider_shape = collision.collider_shape
    ret.collider_shape_index = collision.collider_shape_index
    ret.collider_velocity = collision.collider_velocity
    ret.local_shape = collision.local_shape
    ret.normal = collision.normal
    ret.position = collision.position
    ret.remainder = collision.remainder
    ret.travel = collision.travel
    return ret

var floor_collision = null

export var stair_height = 0.25
export var floor_search_distance = 0.05
#export var stair_query_fallback_distance = 0.05
export var stair_query_fallback_distance = 0.05
# allows 45.5ish degrees and shallower (rad2deg(acos(0.7)) is about 45.573 degrees)
export var floor_normal_threshold = 0.7

export var slopes_are_stairs = false
export var use_fallback_stair_logic = true
export var do_stairs = true
export var stick_to_ground = true


var hit_a_wall = false
var hit_a_floor = false
func is_on_wall():
    return hit_a_wall

func is_on_floor():
    return floor_collision != null

func collision_is_floor(collision):
    if !collision:
        return false
    return collision.normal.y > floor_normal_threshold

func collide_into_floor(motion):
    var max_iters = 4
    var collision = null
    for i in range(max_iters):
        collision = wrap_move_and_collide(motion, false)
        if collision == null:
            break
        else:
            # don't use collision.remainder here - it already does the vector rejection step if using bullet physics
            # FIXME even collision.travel is bad...
            motion -= collision.travel
            if collision_is_floor(collision):
                return [collision, translation, i]
            else:
                motion = vector_reject(motion, collision.normal)
        if motion.length_squared() == 0:
            break
    return null

func collide_into_floor_and_reset(motion):
    var temp_translation = translation
    var stuff = collide_into_floor(motion)
    translation = temp_translation
    return stuff

func map_to_floor(pseudomotion, distance):
    #print("mapping to floor")
    floor_collision = null
    var stuff = collide_into_floor_and_reset(Vector3(0, -(distance+floor_search_distance), 0))
    if stuff == null and pseudomotion != null:
        pseudomotion.y = 0
        pseudomotion = pseudomotion.normalized()
        pseudomotion *= stair_query_fallback_distance
        stuff = collide_into_floor_and_reset(Vector3(pseudomotion.x, -(distance+floor_search_distance), pseudomotion.z))
        #if stuff != null:
            #print("successful map_to_floor fallback")
        #else:
            #print("failed map_to_floor fallback")
            #print(pseudomotion)
    if stuff != null:
        var collision = stuff[0]
        var temp_translation = stuff[1]
        var bounces = stuff[2]
        if collision_is_floor(collision):
            #print("collision was floor (%s)" % collision)
            # the y of temp_translation should be negativer than translation
            var actual_distance = translation.y - temp_translation.y
            if bounces == 0:
                if actual_distance > floor_search_distance:
                    translation.y = temp_translation.y + floor_search_distance
            else:
                translation = temp_translation
            floor_collision = collision
        #else:
            #print("collision is not floor (%s)" % collision)

# b must be normalized
func vector_project(a, b):
    var scalar_projection = a.dot(b)
    var vector_projection = b * scalar_projection
    return vector_projection

# b must be normalized
func vector_reject(a, b):
    var scalar_projection = a.dot(b)
    var vector_projection = b * scalar_projection
    var vector_rejection = a - vector_projection
    return vector_rejection

func move_and_collide_vertically(motion_y):
    return wrap_move_and_collide(Vector3(0, motion_y, 0), false)

# fallback is for physics engine badness at low delta times like 8ms
func attempt_stair_step(motion, raw_velocity, is_wall, fallback = false):
    if !do_stairs:
        return null
    if motion.x == 0 and motion.z == 0:
        return null
    
    var start_translation = translation
    
    var translation_before_upward = translation
    var upward_contact = move_and_collide_vertically(stair_height)
    var translation_after_upward = translation
    
    var actual_upward_motion = stair_height
    if upward_contact:
        actual_upward_motion = translation_after_upward.y - translation_before_upward.y
    
    var original_motion = motion
    
    motion.y = 0
    if fallback:
        motion = motion.normalized()
        motion *= stair_query_fallback_distance
        #print("========")
        #print(motion)
        #print(actual_upward_motion)
    
    var horizontal_contact = wrap_move_and_collide(motion, false)
    
    var down_contact = move_and_collide_vertically(-(actual_upward_motion))
    
    var end_translation = translation
    translation = start_translation
    
    if collision_is_floor(down_contact):
        if -down_contact.travel.y < actual_upward_motion:
            if horizontal_contact:
                return [
                    vector_reject(motion - horizontal_contact.travel, horizontal_contact.normal),
                    end_translation,
                    vector_reject(raw_velocity, horizontal_contact.normal)
                    ]
            else:
                return [Vector3(0, 0, 0), end_translation, raw_velocity]
    #else:
    #    print("found collision was not a floor: %s" % down_contact)
    
    if !use_fallback_stair_logic or fallback or !is_wall:
        return null
    elif motion.length_squared() < stair_query_fallback_distance*stair_query_fallback_distance:
        return attempt_stair_step(original_motion, raw_velocity, is_wall, true)

func custom_move_and_slide(delta, velocity):
    var raw_velocity = velocity
    var delta_velocity = velocity*delta
    
    var start_velocity = velocity
    var start_translation = translation
    var started_on_ground = floor_collision != null
    
    var max_iters = 12
    hit_a_floor = false
    hit_a_wall = false
    for i in range(max_iters):
        var collision = wrap_move_and_collide(delta_velocity, false)
        if collision == null:
            break
        else:
            delta_velocity -= collision.travel
            #print("testing stairs on bounce " + str(i))
            #print("original vel: " + str(raw_velocity))
            #print("delta vel: " + str(delta_velocity))
            
            var stair_residual = null
            var is_wall = !collision_is_floor(collision)
            if slopes_are_stairs or is_wall:
                stair_residual = attempt_stair_step(delta_velocity, raw_velocity, is_wall)
            
            if stair_residual:
                #print("stair residual exists")
                delta_velocity = stair_residual[0]
                translation = stair_residual[1]
                raw_velocity = stair_residual[2]
                raw_velocity.y = 0
                continue
            else:
                #print("no stair data, checking slides")
                # don't use collision.remainder here - it already does the vector rejection step if using bullet physics
                if is_wall:
                    #print("it's a wall")
                    hit_a_wall = true
                    delta_velocity = vector_reject(delta_velocity, collision.normal)
                    raw_velocity = vector_reject(raw_velocity, collision.normal)
                else:
                    #print("it's a floor")
                    hit_a_floor = true
                    
                    var delta_v_horizontal = delta_velocity
                    delta_v_horizontal.y = 0
                    
                    delta_velocity = vector_reject(delta_velocity, collision.normal)
                    raw_velocity.y = 0
                    
                    # retain horizontal velocity going up slopes
                    if delta_velocity.length_squared() != 0:
                        delta_velocity = delta_velocity.normalized()
                        delta_velocity *= delta_v_horizontal.length()
                    
        if delta_velocity.length_squared() == 0:
            #print("breaking early because remaining travel vector empty")
            break
    
    var travel = translation-start_translation
    travel.y = 0
    var travel_horizontal_distance = travel.length()
    
    if !stick_to_ground:
        map_to_floor(null, 0)
    elif started_on_ground:
        map_to_floor(raw_velocity*delta, stair_height)
    elif hit_a_floor or start_velocity.y < 0:
        map_to_floor(null, 0)
    else:
        floor_collision = null
    
    if floor_collision != null:
        raw_velocity.y = 0
    
    return raw_velocity
