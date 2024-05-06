

	var d = function(xx, yy, ease, w = 600, h = 400, step = 1/20, amt = 0) {
		var i;
		yy += h;
		
		draw_set_color(c_gray);
		//draw_text_transformed(xx, yy - h - 20, $"{(ease+1)}. {ease_names[ease]}", 0.7, 1, 0);
		draw_text(xx, yy - h - 20, $"{(ease+1)}. {ease_names[ease]}");
	
		draw_line(xx, yy - h, xx, yy);
		draw_line(xx, yy, xx + w, yy);
		
		draw_set_alpha(0.3);
		draw_line(xx+w/2, yy - h, xx+w/2, yy);
		draw_line(xx, yy-h/2, xx + w, yy-h/2);
		draw_line(xx, yy-h, xx + w, yy-h);
		
		draw_set_alpha(1);
		draw_set_color(c_red);
		
		draw_circle(xx, yy - h*__fx_ease(ease, amt), 5, true);
	
		for(i = 0; i < 1; i+= step) {
			var _a = __fx_ease(ease, i);
			var _b = __fx_ease(ease, i+step);
		
			draw_line(xx + i * w, yy - _a * h, xx + (i+step) * w, yy - _b * h);
		}
	}
	
	ease = (ease + fx_ease_type.__total - keyboard_check_pressed(vk_left) + keyboard_check_pressed(vk_right)) % fx_ease_type.__total
	
	draw_text(10, 10, $"Easing function: {ease_names[ease]}");
	
	d(20, 50, ease,room_width-50,,1/100, progress);
	
	if (await == 0) {
		progress += 0.01 * way;
		if (progress <= 0 or progress >= 1) {
			way *= -1;
			await = 30;
		}
	} else {
		await--;
	}
	
	progress = clamp(progress, 0, 1);
	
	draw_sprite(spr_gm, 0, fx_ease(70, room_width-70, progress, ease), 520);
	var _e;
	
	_e = fx_ease(0, 1, progress, ease);
	draw_sprite_ext(spr_gm, 0, 70, 650, _e, _e, 0, c_white, 1);
	draw_sprite_ext(spr_gm, 0, 70 + 150, 650, _e, 1, 0, c_white, 1);
	draw_sprite_ext(spr_gm, 0, 70 + 300, 650, 1, _e, 0, c_white, 1);
	
	draw_sprite_ext(spr_gm, 0, 70+600, 650, 1, 1, 0, merge_color(c_white, c_red, clamp(_e, 0, 1)), 1);
	
	_e = fx_ease(0, 360, progress, ease);
	draw_sprite_ext(spr_gm, 0, 70+450, 650, 1, 1, _e, c_white, 1);
	