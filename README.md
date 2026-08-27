# GMFX - animations, easing & tweeenings library

Simple animations / easing / tweeenings library.

Create animation, add initial values, then add taraget data ( and call .next() to start another one ).

```gml
fx = new fx_animation({alpha: 0, scale: 0});
fx.anim("alpha", 0.9, 30).anim("scale", 1.5, 20);
```

Above code will animate alpha 0->0.9 for 30 frames, and x/y scale from 0->1.5 in 20 frames (so total length of that part is 30 frames).

Then play it with:

```gml
fx.play();
```

That's all!

---

Check [Wiki](https://github.com/gmclan-org/gmfx_lib/wiki) for full documentation.

---

Created by @gnysek from gmclan.org. Feel free to use. Contributions are welcome.
