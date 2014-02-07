local size = math.max(rp.get_config('size', 1), 1)

-- Let's talk about world generation.
local WGS = radiant.mods.load('stonehearth').world_generation

local function on_initialisation(_, event)
	event.game_seed = 0
end

local function generator_chosen(_, event)
	event.generator.generate_blueprint = function(self) return self:get_empty_blueprint(size, size) end
end

radiant.events.listen(WGS, 'rp:blueprint_generator_chosen', WGS, generator_chosen)
radiant.events.listen(WGS, 'rp:on_initialisation', WGS, on_initialisation)
return true