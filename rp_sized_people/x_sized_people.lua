-- TODO: Move this into a JSON.
-- TODO: make sure the TODO above stays in this code for all eternity.

-- Format: gender = {min %, max % }
local SIZES = 
{
	male = {
		min = 1,
		max = 1.1
	},
	
	female = { 
		min = 0.9,
		max = 1
	}
}

local _
_, SIZES = rp.load_config('config/sized_people.json', SIZES)

-- Function that re-sizes an entity.
local function setSize(ent, gender, index)
	-- Check if we have a size for this cute little fella
	local size = SIZES[gender .. '_' .. index]
	
	-- Validate
	if size and (not size.min or not size.max) then
		rp.logf('Invalid size entry for %s_%d: min/max not found', gender, index)
		size = nil
	end
	
	-- Default to gender
	if not size then
		size = SIZES[gender]
	end
	
	if not size then
		return
	end
	
	-- Determine a random size, we're using 4 digits for that.
	size = math.random(size.min * 1000, size.max * 1000) / 1000

	-- Determine the current height
	local render_info = ent:get_component('render_info')
	-- Apply size; percentual.
	ent:add_component("render_info"):set_scale(size * render_info:get_scale())
	
	-- Set the speed of this entity, which is *inverse*. i.e. the smaller the faster.
	local attributes = ent:get_component('stonehearth:attributes')
	ent:add_component('stonehearth:attributes'):set_attribute('speed', 100 * 1/size)
end

-- For now, there's only 3 citizens and they're either male or female.
for i = 1, 3 do
	for k, gender in pairs({'male', 'female'}) do
		-- Create a hook to mess around with them after they have been created.
		rp.add_entity_created_hook('stonehearth:' .. gender .. '_' .. i, setSize, gender, i)
	end
end