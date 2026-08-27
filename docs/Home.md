Welcome to the gmfx_lib wiki!

Video with example: https://imgur.com/a/jgzgM6w

## Creating animation chain:

```gml
fx = new fx_animation(<params_struct>);
```
Example:
```gml
fx = new fx_animation({alpha: 0});
```

> [!NOTE]
> If you pass struct as reference, you can still access "current" values of animations using that struct. So, this is valid:
> ```gml
> params = {alpha: 0};
> fx = new fx_animation({alpha: 0});
> ...
> var current_alpha = params.alpha; // same as: fx.params.alpha;
> ```

## Adding effect:
There are 3 methods which can be used, all are chainable:

---
### `.anim("param" [, target_value , frames, delay, func])`

Allows to set easiest target for that animation. By default param name (existing in `param` struct) is needed, rest is optional.
By default, `target_value` is 0, `frames` is equal to current game speed (so 60 by default), and `func` is undefined.
Func might be a function or script reference, which takes 3 arguments, similar to [`lerp`](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Maths_And_Numbers/Number_Functions/lerp.htm) function (first value, second value, amount of transition between first and second - doesn't need to be linear). By default animations will use GM built-in `lerp` if this arg is not provided.

`delay` (default `0`) postpones the start of this specific animation by that many frames, counted within the current sequence. The param stays at its start value until the delay elapses. Use it to stagger or offset animations that share a sequence (e.g. start `scale` right away but let `alpha` catch up 10 frames later so they finish together, or hold a param unmoved before letting it animate at the end).

---
### `.anim_more(["params"] [, target_value , frames, delay, func])`

Same as above, but you can provide array of args (other values can't be arrays).

---
### `.color("param"[, color, frames, delay]);`

Alias for creating animation where `func` is equal to `merge_color`. By default color is white (c_white).

---
### `.ease("param"[, value, frames, delay, ease]);`

Alias for creating animation, where `func` is `fx_ease`, and (since `fx_ease` have 4 arguments), ease type is binded using `method()`.
While `ease` is optional, if it is skipped, then normal `anim()` with no function is created.
For ease types, `fx_ease_type` enum can be used (except of `fx_ease_type.__total` which is there to help get amount of available effects).

> [!NOTE]
> Remember, that in recent versions of GM you can skip arguments by putting coma, so doing `ease("alpha",,,, fx_ease_type.out_elastic)` is valid (value will be set to `0`, frames to `60`, and delay to `0` by default)

---
### `.next()`

Starts next "sequence" of params to animate, which would follow after last one from previous sequence is done.

---
### `.override(<instance_id>)`

Sets instance in which variables will be overridden if they matches name of params struct. There's few "magic" params, that would update instance built-in variables, which can be used as aliases:
- "alpha" -> `image_alpha`
- "angle" -> `image_angle`
- "blend", "color" -> `image_blend`
- "image_scale", "scale" -> `image_xscale` + `image_yscale` (both at same time)
- "scale_x", "xscale" -> `image_xscale`
- "scale_y", "yscale" -> `image_yscale`
> [!NOTE]
> Using "xscale"/"yscale" and "scale" at same time leads to undefined behaviour, as it's not known which will be executed earlier.

---
### `.loop()` (not chainable)

enables/disables animation looping, sets to `true` by default

---
### `.restart()` (not chainable)

resets animation to initial params and to first "sequence"

---
### `.play()` (not chainable)

advances animation by 1 frame of current "sequence". Returns `true` if it's last frame of current sequence.

---
### `.finished()` (not chainable)

returns true if animation ended (might never returns true on loopable)

## Example animation:

```gml
/// Create event:
params = {
  scale: 0,
  alpha: 0,
  color: c_white,
  angle: 0,
  x: x,
  y: y,
};

fx = new fx_animation(params);
fx.ease("scale", 2, 80,, fx_ease_type.out_elastic).anim("alpha", 1)
  .next()
  .ease("scale", 1,,,fx_ease_type.smoothest_step).color("color", #22ffff).ease("x", room_width-100,,,fx_ease_type.in_out_back).anim("y", room_height-100).ease("angle", 90,,,fx_ease_type.in_out_cubic)
  .next()
  .anim("scale", 0.5).anim("alpha", 0, 120).color("color", c_lime, 30).ease("angle", 360,,,fx_ease_type.in_out_cubic)
  .override(id) // enables sync with current instance
  .loop(); // enables loop

/// Step event:
fx.play();
```
---

### Easings
By calling `fx_ease(a, b, amt, type)` and passing one of `fx_ease_type` enum values, you can achieve below easings:

![obraz](https://github.com/gmclan-org/gmfx_lib/assets/524094/03936a64-7d2b-4fe9-a0f1-dec13b389f6b)

Available animations:

```gml
enum fx_ease_type {
	linear,
	
	in_quad,
	in_cubic,
	in_quart,
	in_quint,
	
	out_quad,
	out_cubic,
	out_quart,
	out_quint,
	
	in_out_quad,
	in_out_cubic,
	in_out_quart,
	in_out_quint,
	
	in_sine,
	out_sine,
	in_out_sine,
	
	in_expo,
	out_expo,
	in_out_expo,
	
	in_bounce,
	out_bounce,
	in_out_bounce,
	
	in_circ,
	out_circ,
	in_out_circ,
	
	in_back,
	out_back,
	in_out_back,
	
	in_elastic,
	out_elastic,
	in_out_elastic,
	
	smoothest_step,
	smoother_step, 
	smooth_step,   
}
```