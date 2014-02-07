local size = math.max(rp.get_config('size', 1), 1)

-- Let's talk about world generation.
local WGS = radiant.mods.load('stonehearth').world_generation

local function generator_chosen(_, event)
	-- TODO: Have some sort of... proper event here?
	-- But we don't intend on doing anything with this for a while. :(
	event.generator.generate_blueprint = function(self) return self:get_empty_blueprint(size, size) end
end

radiant.events.listen(WGS, 'rp:blueprint_generator_chosen', WGS, generator_chosen)
return true