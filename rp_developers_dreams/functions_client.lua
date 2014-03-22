local F = class()
local Point3f = _radiant.csg.Point3f

function F:setup_camera()
	stonehearth.camera:set_position(Point3f(-3.6, 43.3, 63.8))
	-- Fix: Otherwise, it's just ignored.
	stonehearth.camera._next_position = stonehearth.camera:get_position()
end

return F