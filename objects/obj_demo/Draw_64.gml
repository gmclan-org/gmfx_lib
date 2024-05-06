
	if (debug) {
		fx_debug(fx);
	}
	
	draw_set_alpha(1);
	draw_set_color(c_white);
	draw_set_font(-1);
	
	draw_text(10, 10, "Press Space to play/pause\nPress \"S\" for single frame (when paused)\nPress \"D\" for some debug info.\nPress \"L\" to change loop mode." + (fx.__loop ? " (enabled)" : " (disabled )"));