local size = math.max(rp.get_config('size', 1), 1)

-- Let's talk about world generation.
local WG = rp.load_stonehearth_service('world_generation.world_generator')

local WGS = radiant.mods.load('stonehearth').world_generation


local function propose_generator(_, event)
	local wg = WG(event.async, 0)
	
	wg._create_world_blueprint = function(self) return self:_get_empty_blueprint(size, size) end
	
	table.insert(event.proposals, { priority = 100, generator = wg })
end

radiant.events.listen(WGS, 'stonehearth:propose_world_generator', WGS, propose_generator)

return true