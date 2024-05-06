function fx_animation(_params = {}) constructor {
	params = _params; // if passed as reference, then reference can be readed too
	
	__queue = [[]];
	__queue_time = [0];
	__queue_i = 0;
	__playback_step = 0;
	__playback_frame = 1;
	
	__params = variable_clone(params, 1); // target values
	__original_params = variable_clone(params, 1);
	
	__override = undefined;
	
	__loop = false;
	
	static override = function(_id) {
		if (instance_exists(_id)) {
			__override = _id;
			//if (__playback_step == 0 and __playback_frame == 1) {
			self.__step();
			//}
		}
		
		return self;
	}
	
	/// @desc returns true when frame ends
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
			if (self.__playback_step < self.__queue_i) {
				self.__playback_step++;
				self.__playback_frame = 1;
				__copy_struct_values(self.params, self.__params);
			} else {
				if (self.__loop) {
					self.restart();
				}
			}
			
			return true;
		}
		
		return false;
	}
		
	static loop = function(_loop = true) {
		self.__loop = _loop;
	}
	
	// @desc sets variables according to current frame, but without advancing step/frame
	static __step = function() {
		if (self.finished()) return true; // already played everything that was possible
		
		var _c = undefined, _f = undefined, _p = "";
		var _done = true;
		for (var i = 0, n = array_length(self.__queue[__playback_step]); i < n; i++) {
			_c = self.__queue[__playback_step][i];
			
			if (self.__playback_frame <= _c.frames) {
				if (struct_exists(self.__params, _c.param)) {
				
					_f = (is_undefined(_c.func) or !is_callable(_c.func)) ? lerp : _c.func;
				
					self.params[$ _c.param] = _f(self.__params[$ _c.param], _c.to_val, min(1, __playback_frame/_c.frames));
					self.__override_apply(_c.param, self.params[$ _c.param]);
				}
			}
			
			if (_c.frames > self.__playback_frame) {
				_done = false;
			}
			
			//_done = _done && (_c.frames < self.__playback_frame);
		}
		
		return _done;
	}
	
	static finished = function() {
		if (__playback_step = __queue_i and __playback_frame >= __queue_time[__playback_step]) return true;
		return false;
	}
	
	static restart = function() {
		self.__playback_step = 0;
		self.__playback_frame = 0;
		__copy_struct_values(self.__original_params, self.params);
		__copy_struct_values(self.__original_params, self.__params);
		self.__step();
		self.__playback_frame = 1;
	}
	
	static anim = function(param = "", to_val = 0, frames = game_get_speed(gamespeed_fps), func = undefined) {
		array_push(self.__queue[__queue_i], {
			param,
			to_val,
			frames,
			func
		});
		
		self.__queue_time[__queue_i] = max(self.__queue_time[__queue_i], frames);
		
		return self;
	}
	
	static anim_more = function(params = [""], to_val = 0, frames = game_get_speed(gamespeed_fps), func = undefined) {
		for(var i = 0, n = array_length(params); i < n; i++) {
			self.anim(params[i], to_val, frames, func);
		}
	}
	
	/// @chainable
	static color = function(param = "", to_val = 0, frames = game_get_speed(gamespeed_fps)) {
		self.anim(param, to_val, frames, merge_color);
		return self;
	}
		
	/// @param {String} param
	/// @param {Real} to_val
	/// @param {Real} frames
	/// @param {Real} _ease
	static ease = function(param = "", to_val = 0, frames = game_get_speed(gamespeed_fps), _ease = undefined) {
		if (is_numeric(_ease)) {
			self.anim(param, to_val, frames, self.__make_fx_ease(_ease));
		} else {
			self.anim(param, to_val, frames);
		}
		
		return self;
	}
	
	static __make_fx_ease = function(ease_type) {
		return method({ease: ease_type}, function(a,b,amt) {
			/// feather ignore GM1041 once
			return fx_ease(a, b, amt, ease);
		});
	}
	
	/// @desc sets that from that point, another "stage" of animation will be performed
	static next = function() {
		array_push(self.__queue, []);
		array_push(self.__queue_time, 0);
		__queue_i++;
		
		return self;
	}
	
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