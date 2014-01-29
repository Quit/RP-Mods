local GS = class()

function GS:enable_shooting(session, response, event)
	event.entity:get_component('stonehearth:commands'):enable_command('harvest_shoot', true)
	return true
end

return GS