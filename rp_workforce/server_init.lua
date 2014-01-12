-- Hook the default standard
local MOD = {}

function MOD:_entity_created(event)
	if event.entity_id == 'stonehearth:camp_standard' then
		local commands = event.entity:add_component('stonehearth:commands'):add_command('/rp_workforce/commands/summon_worker')
	end
end


radiant.events.listen(radiant.events, 'stonehearth:entity_created', MOD, MOD._entity_created)
return MOD