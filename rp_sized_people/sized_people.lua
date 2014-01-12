local MOD = class()

-- Format: gender_or_entity_name => { min => min_percent_value, max => max_percent_value }
MOD.SIZES = 
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

function MOD:__init()
	self.SIZES = rp.load_config(self.SIZES)
	self:_load_entity_list()
	radiant.events.listen(radiant.events, 'stonehearth:entity_created', self, self._entity_created)
end

function MOD:set_size(entity, entity_id)
	-- Check if we have a size for this cute little fella
	local size = self.SIZES[entity_id]
	
	-- Validate
	if size and (not size.min or not size.max) then
		rp.logf('Invalid size entry for %s: min/max not found', entity_id)
		size = nil
	end
	
	-- Default to gender
	if not size then
		-- Try to guess its gender?
		if entity_id:find('female') then
			size = self.SIZES.female
		elseif entity_id:find('male') then
			size = self.SIZES.male
		end
	end
	
	if not size or not size.min or not size.max or size.max <= size.min then
		rp.log('[ERROR] Cannot find proper size for %q (min/max: %s/%s)', entity_id, tostring(size and size.min), tostring(size and size.max))
		return
	end
	
	-- Determine a random size, we're using 4 digits for that.
	size = math.random(size.min * 1000, size.max * 1000) / 1000

	-- Determine the current height
	local render_info = entity:add_component('render_info')
	
	-- Apply size; percentual.
	entity:add_component("render_info"):set_scale(size * render_info:get_scale())
end

function MOD:_load_entity_list()
	local entities = {}
	for mod_name, mod in pairs(rp.available_mods) do
		-- Has entities?
		if mod.manifest.radiant and mod.manifest.radiant.entities then
			for entity_id, entity_uri in pairs(mod.manifest.radiant.entities) do
				if entity_uri:find('entities/humans/') then
					entities[mod_name .. ':' .. entity_id] = true
					rp.logf('Found resizable: "%s:%s"', mod_name, entity_id)
				end
			end
		end
	end
	
	self._entity_list = entities
end

function MOD:_entity_created(event)
	if self._entity_list[event.entity_id] then
		self:set_size(event.entity, event.entity_id)
	end
end

-- TODO: Have RP handle this in the future
return MOD()