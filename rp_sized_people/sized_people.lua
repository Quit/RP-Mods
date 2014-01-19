local MOD = class()

-- Format: gender_or_entity_name => { min => min_percent_value, max => max_percent_value }
local DEFAULT_SIZES = 
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
	self:_load_config()
	radiant.events.listen(radiant.events, 'stonehearth:entity_created', self, self._on_entity_created)
	radiant.events.listen(radiant.events, 'stonehearth:faction_created', self, self._on_faction_created)
end

function MOD:_load_config()
	local SIZES = rp.load_config(DEFAULT_SIZES)
	self._sizes = {}
	
	-- Iterate through them; make sure they're valid
	for k, v in pairs(SIZES) do
		if type(v.min) ~= 'number' or type(v.max) ~= 'number' or v.min > v.max then
			rp.logf('Invalid entry for %q!', k)
		else
			self._sizes[k] = v
		end
	end
end

function MOD:set_size(entity, size)
	-- Determine a random size, we're using 4 digits for that.
	size = math.random(size.min * 1000, size.max * 1000) / 1000

	-- Determine the current height
	local render_info = entity:add_component('render_info')
	
	-- Apply size; percentual. Relative.
	entity:add_component("render_info"):set_scale(size * render_info:get_scale())
end

-- For all explicitly defined entities
function MOD:_on_entity_created(event)
	local size = self._sizes[event.entity_id]
	if size then
		self:set_size(event.entity, size)
	end
end

-- For all 
function MOD:_on_faction_created(event)
	radiant.events.listen(event.object, 'stonehearth:citizen_created', self, self._on_citizen_created)
end

function MOD:_on_citizen_created(event)
	-- Check if we have a specific entry for this citizen; in this case we have already dealt with it (prematurely)
	if self._sizes[event.entity_id] then
		return
	end
	
	-- OK, resize us?
	local size = self._sizes[event.gender]
	if size then -- In today's modern world, it's not all black and white anymore
		self:set_size(event.object, size)
	end
end

-- TODO: Have RP handle this in the future
return MOD()