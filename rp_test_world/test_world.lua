-- Enforces the world to be generated as 'test' blueprint.
-- aka "a very small tile".
local WG = rp.load_stonehearth_service('world_generation.world_generator')

local size = math.max(rp.get_config('size', 1), 1)

rp.logf('Size: %d', size)

if not WG then
	error('Could not load WorldGeneration service!')
end

function WG:_create_world_blueprint()
	return self:_get_empty_blueprint(size, size)
end

return true