--[[
	Stuff in here will be moved to RP real soon, but until that is available...
]]--

if rp.constants.VERSION > 2701 then
	return true
end

-- The cleanish part.
local OC = class()

function OC:__init(entity, overlay)
	self._entity = entity
	self._effect = radiant.effects.run_effect(entity, overlay)
	radiant.events.listen(entity, 'stonehearth:renewable_resource_spawned', self, self._on_renewable_resource_spawned)
	self._entity._rp_overlay_checker = self
end

function OC:_on_renewable_resource_spawned()
	self._effect:stop()
	radiant.events.unlisten(self._entity, 'stonehearth:renewable_resource_spawned', self, self._on_renewable_resource_spawned)
	self._entity._rp_overlay_checker = nil
end

-- The absolutely illegal part
do
	local RCH = rp.load_stonehearth_call_handler('resource_call_handler')

	local old_harvest_plant = RCH.harvest_plant

	function RCH:harvest_plant(session, response, plant)
		local ret = { old_harvest_plant(self, session, response, plant) }
		
		radiant.events.trigger(radiant.events, 'stonehearth:plant_marked_for_harvesting', { plant = plant })
		OC(plant, "/stonehearth/data/effects/harvest_berries_overlay_effect")
		return unpack(ret)
	end
end

-- The absolutely condemnable part
do
	local RRNC = _host:require('stonehearth.components.renewable_resource_node.renewable_resource_node_component')
	local old_spawn_resource = RRNC.spawn_resource
	
	function RRNC:spawn_resource(location, ...)
		radiant.events.trigger(self._entity, 'stonehearth:renewable_resource_spawned', { resource = self._resource })
		return old_spawn_resource(self, location, ...)
	end
end

return true