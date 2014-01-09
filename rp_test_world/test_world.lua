-- Enforces the world to be generated as 'test' blueprint.
-- aka "a very small tile".
local WG = rp.load_stonehearth_service('world_generation.world_generator')

if not WG then
	error('Could not load WorldGeneration service!')
end

PrintTable(WG)

function WG:_create_world_blueprint()
	return self:_get_empty_blueprint(1, 1)
end

return true