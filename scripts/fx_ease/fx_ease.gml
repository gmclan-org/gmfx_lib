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
	
	__total
}

/// @desc returns percentage interpolation between "a" and "b", by given "amt" amount (0-1), for given "fx_ease_type." enum
/// @param {Real} a 0% value
/// @param {Real} b 100% value
/// @param {Real} amt percentage amount, 0-1, it's clamped
/// @param {Enum.fx_ease_type} type easing animation from fx_ease_type enum list
function fx_ease(a = 0, b = 0, amt = 0, type = fx_ease_type.linear) {
	return a + (b - a) * __fx_ease(type, clamp(amt, 0, 1));
}


/// initializes and returns easing interpolation for given percentage (0-1)
/// based on offalynne easings
/// Source: https://github.com/offalynne/easings.gml/blob/main/scripts/easings/easings.gml
/// License: https://github.com/offalynne/easings.gml/blob/main/LICENSE
/// @param {Enum.fx_ease_type, Real} _type easing animation from fx_ease_type enum list
/// @param {Real} _amt percentage amount, 0-1, !not clamped!
function __fx_ease(_type = fx_ease_type.linear, _amt = 0) {
	static __cache = new(
		function() constructor {
			var __set = function(_name, _function, _struct = self) { 
				struct_set(_struct, _name, _function);
				return struct_get(_struct, _name);
			};
			//Epsilon-safe square root
			__sqrt = function(a) { return (sign(a) == 1)? sqrt(a) : 0; };
			
			__set(fx_ease_type.linear, function(a) { return a; });
			
			__set(fx_ease_type.in_quad, function(a)  { return power(a, 2); });
			__set(fx_ease_type.in_cubic, function(a) { return power(a, 3); });
			__set(fx_ease_type.in_quart, function(a) { return power(a, 4); });
			__set(fx_ease_type.in_quint, function(a) { return power(a, 5); });
			
			__set(fx_ease_type.out_quad, function(a)  { return 1 - power(1 - a, 2); });
			__set(fx_ease_type.out_cubic, function(a) { return 1 - power(1 - a, 3); });
			__set(fx_ease_type.out_quart, function(a) { return 1 - power(1 - a, 4); });
			__set(fx_ease_type.out_quint, function(a) { return 1 - power(1 - a, 5); });
			
			__set(fx_ease_type.in_out_quad, function(a)  { return a < 0.5 ? power(a, 2) * 2 : 1 - power(-2 * a + 2, 2)/2; });
			__set(fx_ease_type.in_out_cubic, function(a) { return a < 0.5 ? power(a, 3) * 4 : 1 - power(-2 * a + 2, 3)/2; });
			__set(fx_ease_type.in_out_quart, function(a) { return a < 0.5 ? power(a, 4) * 8 : 1 - power(-2 * a + 2, 4)/2; });
			__set(fx_ease_type.in_out_quint, function(a) { return a < 0.5 ? power(a, 5) *16 : 1 - power(-2 * a + 2, 5)/2; });
			
			__set(fx_ease_type.in_sine, function(a) { return 1 - cos((a*pi)/2) });
			__set(fx_ease_type.out_sine, function(a) { return sin((a*pi)/2) });
			__set(fx_ease_type.in_out_sine, function(a) { return -(cos(a*pi)-1)/2 });
			
			__set(fx_ease_type.in_expo, function(a) {return (a == 0) ? 0 : power(2, 10 * a - 10); });
			__set(fx_ease_type.out_expo, function(a) {return (a == 1) ? 1 : 1 - power(2, -10 * a); });
			__set(fx_ease_type.in_out_expo, function(a) {
			        if (a == 0.0) { return 0; }
			        if (a == 1.0) { return 1; }
			        if (a >= 0.5) { return (2 - power(2, -20 * a + 10))/2; }
			        return power(2, 20 * a - 10)/2;
			});
			
			// bounce
			__out_bounce = __set(fx_ease_type.out_bounce, function(a) {
				if (a < 1.0/2.75) { return 7.5625*a*a; }
		        else if (a < 2.0/2.75) { a -= (1.5  /2.75); return 7.5625*a*a + 0.75; }
		        else if (a < 2.5/2.75) { a -= (2.25 /2.75); return 7.5625*a*a + 0.9375; }
				
				a -= (2.625/2.75);
				return 7.5625*a*a + 0.984375;
			});
			__set(fx_ease_type.in_bounce, function(a) { return 1 - __out_bounce(1 - a) });
			__set(fx_ease_type.in_out_bounce, function(a) {
				if (a < 0.5) {
					return (1 - __out_bounce(1 -  2*a))/2;
				}
	            return (1 + __out_bounce(2*a -  1))/2;
			});
			
			// circ
			__set(fx_ease_type.in_circ,    function(a) { return 1 - __sqrt(1 - power( a,      2)) });
		    __set(fx_ease_type.out_circ,   function(a) { return     __sqrt(1 - power((a - 1), 2)) });
		    __set(fx_ease_type.in_out_circ, function(a) {
		        if (a >= 0.5) {
					return (1 + __sqrt(1 - power(-2*a + 2, 2)))/2;
				}
		        return (1 - __sqrt(1 - power(2*a, 2)))/2;
			});
								 
			// back
			__set(fx_ease_type.in_back,    function(a) { return 2.70158*power(a, 3) - 1.70158*power(a, 2) });
		    __set(fx_ease_type.out_back,   function(a) { return 1 + 2.70158*power(a - 1, 3) + 1.70158*power(a - 1, 2);});
		    __set(fx_ease_type.in_out_back, function(a) {
		        if (a >= 0.5) {
					return (power(2*a - 2, 2)*(3.5949095*(a*2 - 2) + 2.5949095) + 2)/2;
				}
		        return (power(2*a, 2)*(3.5949095*(a*2) - 2.5949095))/2;
			});
			
			// elastic
			__set(fx_ease_type.in_elastic, function(a) {
		    	static __c = 2*pi/3;
		        if (a == 0.0) { return 0; }
		        if (a == 1.0) { return 1; }
		        return -power(2, 10*a - 10) * sin((a*10 - 10.75)*__c);
			});

		    __set(fx_ease_type.out_elastic, function(a) {
		    	static __c = 2*pi/3;
		        if (a == 0.0) { return 0; }
		        if (a == 1.0) { return 1; }
		        return power(2, -10*a) * sin((a*10 - 0.75)*__c) + 1;
			});        

		    __set(fx_ease_type.in_out_elastic, function(a) {
		    	static __c = 2*pi/4.5;
		        if (a == 0.0) { return 0 }
		        if (a == 1.0) { return 1 }
		        if (a >= 0.5) {
					return power(2, -20*a + 10)*sin((20*a - 11.125)*__c) /2 + 1;
				}
		        return -(power(2,  20*a - 10)*sin((20*a - 11.125)*__c))/2;
			});
								 
			// smooth
			__set(fx_ease_type.smoothest_step, function(a) { return -20 * power(a, 7) + 70 * power(a, 6) - 84 * power(a, 5) + 35 * power(a, 4); });
		    __set(fx_ease_type.smoother_step,  function(a) { return a * a * a *(a * (a * 6 - 15) + 10); });
		    __set(fx_ease_type.smooth_step,    function(a) { return a * a * (3 - 2 * a); });
			
			// end
		})();
	
	return __cache[$ _type](clamp(_amt, 0, 1));
}