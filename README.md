# QuakelikeBody
A vaguely quake-like movement solver for Godot 3.

## License

Creative Commons Zero, 1.0. See repository. In other words: public domain.

## How to use

Drop `QuakelikeBody.gd` into your project, then use `QuakelikeBody` in the scene/node editor instead of `KinematicBody`. Then use `velocity = custom_move_and_slide(delta, ...)` instead of `velocity = move_and_slide(...)`.

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
