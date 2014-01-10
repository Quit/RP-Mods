-- TODO: make sure the TODO above stays in this code for all eternity.

-- Format: gender_or_entity_name => { min => min_percent_value, max => max_percent_value }
local SIZES = 
{
	male = {
		min = 0.95,
		max = 1.05
	},
	
	female = { 
		min = 0.9,
		max = 1
	}
}

SIZES = rp.load_config('config/sized_people.json', SIZES)

-- Function that re-sizes an entity.
local function set_size(ent, ent_name)
	-- Check if we have a size for this cute little fella
	local size = SIZES[ent_name]
	
	-- Validate
	if size and (not size.min or not size.max) then
		rp.logf('Invalid size entry for %s_%d: min/max not found', gender, index)
		size = nil
	end
	
	-- Default to gender
	if not size then
		-- Try to guess its gender?
		if ent_name:find('female') then
			size = SIZES.female
		elseif ent_name:find('male') then
			size = SIZES.male
		end
	end
	
	if not size or not size.min or not size.max or size.max <= size.min then
		rp.log('[ERROR] Cannot find proper size for %q (min/max: %s/%s)', ent_name, tostring(size and size.min), tostring(size and size.max))
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
	attributes:set_attribute('speed', attributes:get_attribute('speed') * 1/size)
end

for mod_name, mod in pairs(rp.available_mods) do
	-- Has entities?
	if mod.manifest.radiant and mod.manifest.radiant.entities then
		for ent_name, ent_uri in pairs(mod.manifest.radiant.entities) do
			if ent_uri:find('entities/humans/') then
				rp.add_entity_created_hook(mod_name .. ':' .. ent_name, set_size, mod_name .. ':' .. ent_name)
				rp.logf('Found resizable: "%s:%s"', mod_name, ent_name)
			end
		end
	end
end

return true