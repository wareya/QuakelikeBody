# QuakelikeBody
A vaguely quake-like movement solver for Godot 3.

## License

Creative Commons Zero, 1.0. See repository. In other words: public domain.

## How to use

Drop `QuakelikeBody.gd` into your project, then use `QuakelikeBody` in the scene/node editor instead of `KinematicBody`. Then use `velocity = custom_move_and_slide(delta, ...)` instead of `velocity = move_and_slide(...)`.

If you have jumping logic, set `floor_collision` to `null` when the character jumps.

Make sure your scripts say `extends QuakelikeBody` instead of `extends KinematicBody`.

![image](https://user-images.githubusercontent.com/585488/132180422-8fac916b-7ae0-4a8b-9a79-b1fb785d87d5.png)

![image](https://user-images.githubusercontent.com/585488/132181276-3693d8da-b300-48bb-817b-5422eb3c5f09.png)

![image](https://user-images.githubusercontent.com/585488/132180474-ea0303da-7f54-4410-b9a6-c9fd8b357758.png)

## Example

Used in the game jam game [Still Waiting](https://github.com/wareya/StillWaiting).

## Where's all the customization?

It's in the exported variables here:

![image](https://user-images.githubusercontent.com/585488/132180793-20e8cf3f-d627-4e5c-ad5e-e5c144975654.png)

All distances are Godot units.

## FAQ:

Q: Why?

A: Because `move_and_slide` and `move_and_slide_with_snap` work in ways that bring out a lot of bugs in godot's physics backends (both bullet and godotphysics).

Q: My jumping code isn't working!

A: Set `floor_collision` to `null` in your jumping code. This movement solver decides whether to snap to the floor based on whether this variable is null or not.

Q: I'm hovering over the ground a little.

A: Reduce `floor_search_distance` until the hovering is unnoticable. A little hovering is unavoidable.

Q: My characters spawn a little above the ground even though they shouldn't be, what gives?

A: Increase `floor_search_distance` until this doesn't happen.

Q: I can't find a value of `floor_search_distance` that doesn't cause either of these problems!

A: Blame the weird bad way that Godot collision margins work, and hope that they get fixed in the future.

Q: I'm snagging on trimesh geometry when using an AABB/Cylinder.

A: Try enabling this flag in your project settings:

![image](https://user-images.githubusercontent.com/585488/132182328-96aa6631-84f0-4665-9310-5a192ac42860.png)

Q: Is this really a clone of quake's movement code?

A: No. It just coincidentally happens to take the same approaches to certain key things. I learned these approaches working on Gang Garrison 2, not Quake mods. There are many small differences, and it is not structured similarly on a code level. Naming it after Quake is just good advertising.
