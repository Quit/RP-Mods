local F = class()
	
if radiant.is_server then
	local Point2, Point3 = _radiant.csg.Point2, _radiant.csg.Point3
	local ich = radiant.mods.require('stonehearth.call_handlers.inventory_call_handler')()
	
	function F:create_stockpile(session, response, x, y, z, w, h)
		return ich:create_stockpile(session, response, Point3(x, y, z), Point2(w, h))
	end
else
	local Point3f = _radiant.csg.Point3f

	function F:setup_camera()
		stonehearth.camera:set_position(Point3f(-3.6, 43.3, 63.8))
		-- Fix: Otherwise, it's just ignored.
		stonehearth.camera._next_position = stonehearth.camera:get_position()
	end
end

return F