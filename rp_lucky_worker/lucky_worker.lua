local maleCreated = false

-- Copypaste, again, from NewGameHandler with modifications
local pop_service = radiant.mods.load('stonehearth').population
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

return true