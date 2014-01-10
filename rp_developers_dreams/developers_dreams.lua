-- Let's talk about world generation.
local WG = rp.load_stonehearth_service('world_generation.world_generator')

local oldInit = WG.__user_init

function WG:__init(async, seed)
	return oldInit(self, async, 0) -- seed is always zero.
end

-- It's a tiny tiny - how often did I say this already
function WG:_create_world_blueprint()
	return self:_get_empty_blueprint(1, 1)
end