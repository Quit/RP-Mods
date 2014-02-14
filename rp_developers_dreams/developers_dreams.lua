local size = math.max(rp.get_config('size', 2), 2)

-- Let's talk about world generation.
local WGS = radiant.mods.load('stonehearth').world_generation

local function set_seed(event)
	event.seed = 0
end

local function generator_chosen(event)
	local get_empty = event.generator.get_empty_blueprint
	
	event.generator.generate_blueprint = function(self) return get_empty(self, size, size) end
	event.generator.get_empty_blueprint = event.generator.generate_blueprint
end

radiant.events.listen(WGS, 'rp:blueprint_generator_chosen', generator_chosen)
radiant.events.listen(WGS, 'rp:set_seed', set_seed)
return true