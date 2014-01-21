--[[
	Stuff in here will be moved to RP real soon, but until that is available...
]]--

local OC = class()

function OC:__init(entity, overlay)
	self._entity = entity
	self._effect = radiant.effects.run_effect(entity, overlay)
	radiant.events.listen(self._entity, 'stonehearth:renewable_resource_spawned', self, self._on_renewable_resource_spawned)
	self._entity._rp_overlay_checker = self
end

function OC:_on_renewable_resource_spawned()
	self._effect:stop()
	radiant.events.unlisten(self._entity, 'stonehearth:renewable_resource_spawned', self, self._on_renewable_resource_spawned)
	self._entity._rp_overlay_checker = nil
end

local MOD = class()

function MOD:__init()
	radiant.events.listen(radiant.events, 'stonehearth:plant_marked_for_harvesting', self, self._on_marked)
end

function MOD:_on_marked(event)
	OC(event.entity, "/stonehearth/data/effects/harvest_berries_overlay_effect")
end

return MOD()