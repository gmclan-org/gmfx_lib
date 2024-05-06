
	//quest_fx.play();
	
	if (play) {
		fx.play();
	}
	
	if (keyboard_check_pressed(vk_space)) {
		if (play and fx.finished()) {
			fx.restart();
		} else {
			play = !play;
		}
	}
	
	if (keyboard_check(ord("S"))) {
		if (!play) {
			if (last_step < (current_time - 150)) {
				fx.play();
				last_step = current_time;
			}
		}
	}
	if (keyboard_check_released(ord("S"))) {
		last_step = 0;
	}
	
	if (keyboard_check_pressed(ord("D"))) {
		debug = !debug;
	}
	
	if (keyboard_check_pressed(ord("L"))) {
		fx.__loop = !fx.__loop;
	}
	
	//fake_progress += way * 0.01;
	//var _pause = 0.5;
	//if (fake_progress >= 1+_pause or fake_progress <= 0-_pause) {
	//	way *= -1;
	//}
	
	//progress = clamp(fake_progress, 0, 1);
	
	