local MOD = class()

function MOD:__init()
	radiant.events.listen(radiant.events, 'rp:faction_created', self, self._on_faction_created)
end

-- Completely cheaty: Check.
local function propose_citizen_gender(faction, event)
	local gender = not faction._rp_lw_created and 'male' or 'female'
	faction._rp_lw_created = true
	table.insert(event.proposals, { priority = 100, gender = gender })
end

function MOD:_on_faction_created(event)
	-- Listen to said faction's creation stuff.
	radiant.events.listen(event.object, 'rp:propose_citizen_gender', event.object, propose_citizen_gender)
end

return MOD()