local maleCreated = false

-- Copypaste, again, from NewGameHandler with modifications
local pop_service = api.population
local faction = pop_service:get_faction("civ", "stonehearth:factions:ascendancy")

local oldCreateCitizen = faction.create_new_citizen

function faction:create_new_citizen()
	local gender = 'female'
	
	if not maleCreated then
		maleCreated = true
		gender = 'male'
	end
	
	local entities = self._data[gender .. "_entities"]
  local kind = entities[math.random(#entities)]
  local citizen = radiant.entities.create_entity(kind)
  citizen:add_component("unit_info"):set_faction(self._faction_name)
  self:_set_citizen_initial_state(citizen, gender)
  return citizen
end

--~ local i = 0

--~ local function createEden(entName)
--~ 	-- Did we already create our male?
--~ 	if not maleCreated then
--~ 		maleCreated = true
--~ 		return 'stonehearth:male_' .. math.random(1, 3)
--~ 	else
--~ 		i = i + 1	
--~ 		rp.log('Creating ', (i % 3) + 1)
--~ 		return 'stonehearth:female_' .. ((i % 3) + 1)
--~ 	end
--~ end

--~ -- For now, there's only 3 citizens and they're either male or female.
--~ for i = 1, 3 do
--~ 	for k, gender in pairs({'male', 'female'}) do
--~ 		-- Create a hook to mess around with them after they have been created.
--~ 		rp.set_entity_proxy('stonehearth:' .. gender .. '_' .. i, createEden)
--~ 	end
--~ end