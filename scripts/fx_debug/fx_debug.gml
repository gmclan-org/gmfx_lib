/// @param {Struct.fx_animation} _fx
function fx_debug(_fx) {
	var _f = array_length(_fx.__queue);
	var _total_length = 0;
	var _segment_lengths = array_create(_f, 0);
	var _total_played = 0;
	
	for(var i = 0; i < _f; i++) {
		var _frames = 0;
		for(var j = 0, n = array_length(_fx.__queue[i]); j < n; j++) {
			_frames = max(_frames, _fx.__queue[i][j].frames);
		}
		_segment_lengths[i] = _frames;
		_total_length += _frames;
		if (i < _fx.__playback_step) {
			_total_played += _frames;
		}
	}
	
	_total_played += _fx.__playback_frame;
	
	draw_set_alpha(1);
	draw_set_color(c_white);
	draw_set_font(-1);
	
	var _params = struct_get_names(_fx.params);
	var _pcount = array_length(_params);
	
	for(var i = 0; i < _pcount; i++) {
		draw_text(20, room_height - 45 - i * 15, _params[i]);
		draw_text(100, room_height - 45 - i * 15, _fx.__params[$ _params[i]]);
		
		if (!_fx.finished()) {
			for(var j = 0, n = array_length(_fx.__queue[_fx.__playback_step]); j < n; j++) {
				if (_fx.__queue[_fx.__playback_step][j].param == _params[i]) {
					draw_text(200, room_height - 45 - i * 15, "-> " + string(_fx.__queue[_fx.__playback_step][j].to_val));
				}
			}
		}
		
		draw_text(300, room_height - 45 - i * 15, "= " + string(_fx.params[$ _params[i]]));
		draw_text(500, room_height - 45 - i * 15, _fx.__original_params[$ _params[i]]);
	}
	
	draw_text(100, room_height - 45 - _pcount * 15, "Start");
	draw_text(200, room_height - 45 - _pcount * 15, "Target");
	draw_text(300, room_height - 45 - _pcount * 15, "Current");
	draw_text(500, room_height - 45 - _pcount * 15, "Initial");
	
	if (!_fx.finished()) {
		draw_text(20, room_height - 100 - _pcount * 15, $"{_fx.__playback_frame}/{_segment_lengths[_fx.__playback_step]}, {_total_played}/{_total_length}");
	}
	
	var _w = room_width - 40;
	
	//draw_rectangle(20, room_height-20, 20+_w, room_height-10, true);
	
	var _xx = 0;
	var _sw = 0;
	
	for(var i = 0; i < _f; i++) {
		_sw = _segment_lengths[i] / _total_length * _w;
		
		draw_set_color(c_white);
		draw_rectangle(20+_xx, room_height-20, 20+_xx+_sw, room_height-10, true);
		
		
		if (i <= _fx.__playback_step) {
			var _progress = _sw;
			if (i == _fx.__playback_step) {
				_progress = _fx.__playback_frame / _segment_lengths[i] * _sw;
			}
			draw_set_color(c_red);
			//draw_rectangle(20+_xx, room_height-20, 20+_xx+_sw, room_height-10, i != _fx.__playback_step);
			draw_rectangle(20+_xx, room_height-20, 20+_xx+_progress, room_height-10, false);
			//draw_set_color(c_red);
			//draw_line(20+_xx+_progress, room_height-25, 20+_xx+_progress, room_height-5);
		}
		
		_xx += _sw;
	}
}