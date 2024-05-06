	params = {
		scale: 0,
		scale_x: 1,
		scale_y: 1,
		alpha: 0,
		color: c_white,
		angle: 0,
		x: x,
		y: y,
	};
	
	fx = new fx_animation(params);
	
	fx
		.ease("scale", 2, 80,fx_ease_type.out_elastic).anim("alpha", 1)
		.next()
		.ease("scale", 1,,fx_ease_type.smoothest_step).color("color", #22ffff).ease("x", room_width-100,,fx_ease_type.in_out_back).anim("y", room_height-100).ease("angle", 90,,fx_ease_type.in_out_cubic)
		.next()
		.anim("scale", 0.5).anim("alpha", 0, 120).color("color", c_lime, 30).ease("angle", 360,,fx_ease_type.in_out_cubic)
		.override(id)
		//.loop()
	;
	
	// rb
		//.ease("scale_x", 1.25, 10).ease("scale_y", 0.75, 10)
		//.next()
		//.ease("scale_x", 0.75, 10).ease("scale_y", 1.25, 10)
		//.next()
		//.ease("scale_x", 1.15, 10).ease("scale_y", 0.85, 10)
		//.next()
		//.ease("scale_x", 0.95, 10).ease("scale_y", 1.05, 10)
		//.next()
		//.ease("scale_x", 1.05, 10).ease("scale_y", 0.95, 10)
		//.next()
		//.ease("scale_x", 1, 10).ease("scale_y", 1, 10)
		//.next()
	// end
	
	//quest_params = {
	//	scale: 0,
	//	alpha: 0,
	//	x: room_width/2,
	//	y: room_height/2,
	//};
	
	//quest_fx = new fx_animation(quest_params);
	
	//quest_fx
	//	.ease("alpha", 1, fx_ease_type.in_elastic).ease("scale", 1, fx_ease_type.in_bounce)
	//	.next()
	//	.ease("", 0) // wait 1 second
	//	.next()
	//	.ease("y", room_height * 1/4, 30, fx_ease_type.in_out_elastic)
	//	.next()
	//	.ease("alpha", 0, fx_ease_type.out_elastic).ease("scale", 0.1, fx_ease_type.in_elastic).ease("y", -100)
	//	.loop();
	
	/// demo
	play = true;
	last_step = 0;
	debug = true;