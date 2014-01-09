-- Enforces the world to be generated as 'test' blueprint.
-- aka "a very small tile".
local WG = rp.load_stonehearth_service('world_generation.world_generator')

if not WG then
	error('Could not load WorldGeneration service!')
end

if WG._create_test_blueprint then
	WG._create_world_blueprint = WG._create_test_blueprint
else
	error('_create_test_blueprint does no longer exist?')
end

return true