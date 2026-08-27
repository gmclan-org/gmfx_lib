function fx_animation(_params = {}) constructor {
	params = _params; // if passed as reference, then reference can be readed too
	
	__queue = [[]];
	__queue_time = [0];
	__on_finish = [undefined];
	__queue_i = 0;
	__playback_step = 0;
	__playback_frame = 1;
	
	__params = variable_clone(params, 1); // target values
	__original_params = variable_clone(params, 1);
	
	__override = undefined;
	
	__loop = false;
	
	/// @desc binds an instance whose built-in variables (image_alpha, image_angle, ...) will be
	///       synced whenever a matching param changes; applies current frame values immediately.
	/// @param {Id.Instance} _id
	/// @chainable
	static override = function(_id) {
		if (__override != _id and instance_exists(_id)) {
			__override = _id;
			//if (__playback_step == 0 and __playback_frame == 1) {
			self.__step();
			//}
		}
		
		return self;
	}
	
	/// @desc advances playback by exactly 1 frame: applies current frame's values (via __step),
	///       then moves the frame/sequence cursor forward. Call this once per Step event.
	///       If already finished and not looping, does nothing and returns true.
	/// @return {Bool} true if this call ended the current sequence (last frame of it), or if
	///                the whole animation was already finished; false if mid-sequence.
	static play = function() {
		if (self.finished()) {
			if (!self.__loop) {
				return true;
			}
		}
		
		self.__step();
		
		if (self.__playback_frame < self.__queue_time[ self.__playback_step ]) {
			self.__playback_frame++;
		} else {
			var _finished_step = self.__playback_step;

			if (self.__playback_step < self.__queue_i) {
				self.__playback_step++;
				self.__playback_frame = 1;
				__copy_struct_values(self.params, self.__params);
			} else {
				if (self.__loop) {
					self.restart();
				}
			}

			if (is_callable(self.__on_finish[_finished_step])) {
				self.__on_finish[_finished_step]();
			}

			return true;
		}
		
		return false;
	}
		
	/// @desc enables/disables looping (restarts from sequence 0 once the last sequence finishes)
	/// @param {Bool} _loop
	/// @not-chainable
	static loop = function(_loop = true) {
		self.__loop = _loop;
	}
	
	/// @desc recalculates and writes params for the CURRENT __playback_step/__playback_frame
	///       (i.e. re-evaluates "now", it does NOT move the cursor forward - that's play()'s job).
	///       Used by play() each tick, and also called directly by override()/restart() to
	///       force an immediate re-sync without advancing playback.
	/// @return {Bool} true if every anim() in the current sequence has reached its frame count
	static __step = function() {
		if (self.finished()) return true; // already played everything that was possible

		var _c = undefined, _f = undefined, _p = "", _local_frame = 0;
		var _done = true;
		for (var i = 0, n = array_length(self.__queue[__playback_step]); i < n; i++) {
			_c = self.__queue[__playback_step][i];
			_local_frame = self.__playback_frame - _c.delay;

			if (_local_frame >= 1 and _local_frame <= _c.frames) {
				if (struct_exists(self.__params, _c.param)) {

					_f = (is_undefined(_c.func) or !is_callable(_c.func)) ? lerp : _c.func;

					self.params[$ _c.param] = _f(self.__params[$ _c.param], _c.to_val, min(1, _local_frame/_c.frames));
					self.__override_apply(_c.param, self.params[$ _c.param]);
				}
			}

			if (_c.delay + _c.frames > self.__playback_frame) {
				_done = false;
			}

			//_done = _done && (_c.frames < self.__playback_frame);
		}

		return _done;
	}
	
	/// @desc true if playback is on the last sequence AND has reached/passed its frame count.
	///       On a looping animation this will still return true briefly at the end of the last
	///       sequence, right before play() calls restart() on the next call.
	/// @return {Bool}
	static finished = function() {
		if (__playback_step == __queue_i and __playback_frame >= __queue_time[__playback_step]) return true;
		return false;
	}
	
	/// @desc resets playback to sequence 0 / frame 1 and restores params to their initial values
	///       (the ones passed to the constructor). Also re-applies override sync immediately.
	/// @not-chainable
	static restart = function() {
		self.__playback_step = 0;
		self.__playback_frame = 0;
		__copy_struct_values(self.__original_params, self.params);
		__copy_struct_values(self.__original_params, self.__params);
		self.__step();
		self.__playback_frame = 1;
	}
	
	/// @desc queues an animation for a single param in the CURRENT sequence (i.e. since the last
	///       next(), or since creation). Runs in parallel with any other anim()/color()/ease()
	///       queued in the same sequence.
	/// @param {String} param   name of a key existing in `params`
	/// @param {Real} to_val    target value
	/// @param {Real} frames    duration in frames
	/// @param {Real} delay     frames to wait (within the current sequence) before this anim starts;
	///                         value stays at its start value until the delay has elapsed
	/// @param {Function} func  interpolation function(from, to, amt), default is lerp
	/// @chainable
	static anim = function(param = "", to_val = 0, frames = game_get_speed(gamespeed_fps), delay = 0, func = undefined) {
		array_push(self.__queue[__queue_i], {
			param,
			to_val,
			frames,
			func,
			delay
		});

		self.__queue_time[__queue_i] = max(self.__queue_time[__queue_i], delay + frames);

		return self;
	}

	/// @desc same as anim(), but queues the same to_val/frames/delay/func for a list of params at once
	/// @param {Array<String>} params
	/// @param {Real} to_val
	/// @param {Real} frames
	/// @param {Real} delay
	/// @param {Function} func
	/// @not-chainable (returns undefined; call anim()/anim_more() again to keep chaining)
	static anim_more = function(params = [""], to_val = 0, frames = game_get_speed(gamespeed_fps), delay = 0, func = undefined) {
		for(var i = 0, n = array_length(params); i < n; i++) {
			self.anim(params[i], to_val, frames, delay, func);
		}
	}

	/// @desc shortcut for anim() using merge_color as the interpolation function
	/// @param {String} param
	/// @param {Constant.Color} to_val
	/// @param {Real} frames
	/// @param {Real} delay
	/// @chainable
	static color = function(param = "", to_val = c_white, frames = game_get_speed(gamespeed_fps), delay = 0) {
		self.anim(param, to_val, frames, delay, merge_color);
		return self;
	}

	/// @desc shortcut for anim() using fx_ease() as the interpolation function
	/// @param {String} param
	/// @param {Real} to_val
	/// @param {Real} frames
	/// @param {Real} delay
	/// @param {Enum.fx_ease_type} _ease  if omitted, falls back to plain anim() (lerp)
	/// @chainable
	static ease = function(param = "", to_val = 0, frames = game_get_speed(gamespeed_fps), delay = 0, _ease = undefined) {
		if (is_numeric(_ease)) {
			self.anim(param, to_val, frames, delay, self.__make_fx_ease(_ease));
		} else {
			self.anim(param, to_val, frames, delay);
		}

		return self;
	}
	
	/// @desc builds an interpolation function(a,b,amt) bound to a fixed fx_ease_type, for ease()
	static __make_fx_ease = function(ease_type) {
		return method({ease: ease_type}, function(a,b,amt) {
			/// feather ignore GM1041 once
			return fx_ease(a, b, amt, ease);
		});
	}
	
	/// @desc closes the current sequence and starts a new one: subsequent anim()/color()/ease()
	///       calls will run only after everything queued before this next() has finished.
	/// @chainable
	static next = function() {
		array_push(self.__queue, []);
		array_push(self.__queue_time, 0);
		array_push(self.__on_finish, undefined);
		__queue_i++;

		return self;
	}

	/// @desc sets a single callback fired once, when the CURRENT sequence finishes (i.e. the one
	///       being built since the last next(), or since creation if called before any next()).
	///       Unlike anim()/color()/ease(), this is not per-param - only one callback per sequence.
	///       Calling it again for the same sequence replaces the previous callback.
	/// @param {Function} func
	/// @chainable
	static on_finish = function(func = undefined) {
		self.__on_finish[__queue_i] = func;
		return self;
	}
	
	/// @desc pushes a single param's current value onto the overridden instance, mapping known
	///       aliases (alpha/angle/blend/color/scale/...) to their image_* built-in variables.
	static __override_apply = function(_p, _v) {
		if (!is_undefined(__override)) {
			if (instance_exists(__override)) {
				
				// change "_p"
				switch(_p) {
					case "alpha":
						_p = "image_alpha";
						break;
						
					case "angle":
						_p = "image_angle";
						break;
						
					case "blend":
					case "color":
						_p = "image_blend";
						break;
				}
				
				switch(_p) {
					case "image_scale":
					case "scale":
						__override.image_xscale = _v;
						__override.image_yscale = _v;
						if (struct_exists(self.params, "scale_x")) self.params.scale_x = _v;
						if (struct_exists(self.params, "xscale")) self.params.scale_x = _v;
						if (struct_exists(self.params, "scale_y")) self.params.scale_y = _v;
						if (struct_exists(self.params, "yscale")) self.params.yscale = _v;
						break;
						
					case "scale_x":
					case "xscale":
						__override.image_xscale = _v;
						break;
						
					case "scale_y":
					case "yscale":
						__override.image_yscale = _v;
						break;
								
					default:
						//show_debug_message([_p, variable_instance_exists(__override, _p) ? "yes" : "no"]);
					
						if (variable_instance_exists(__override, _p)) {
							variable_instance_set(__override, _p, _v);
						}
				}
			} else {
				__override = undefined; // reset if it's destroyed
			}
		}
	}
	
	/*static __smooth_step = function(current, target, step) {
	    step = abs(step);

	    if (current >= (target+step)) {
	        return current - step;
	    } else if (current <= (target-step)) {
	        return current + step;
	    } else {
	        return target;
	    }
	}*/
		
	/// @desc copies matching keys from s_from into s_to in place (keeps s_to's struct reference),
	///       and re-applies override sync for each copied key
	static __copy_struct_values = function(s_from, s_to) {
		// this copies values, without loosing reference
		var _names = struct_get_names(s_from);
		for(var i = 0, n = array_length(_names); i < n; i++) {
			if (struct_exists(s_to, _names[i])) {
				struct_set(s_to, _names[i], s_from[$ _names[i]]);
				__override_apply(_names[i], s_from[$ _names[i]]);
			}
		}
	}
		
	/// @desc draws current playback state (step, frame, params, finished, loop) at (10,10) for debugging
	static __debug = function() {
		draw_text(10, 10, json_stringify({
			__playback_step,
			__playback_frame,
			params,
			__original_params,
			finished: self.finished(),
			__loop,
		},true, function(_k, _v) {
			if (is_real(_v)) {
				return string(round(_v * 1000) / 1000);
			}
			return _v;
		}));
	}
}