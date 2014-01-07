local SummonWorkerHandler = class()
local Point3 = _radiant.csg.Point3
local api = radiant.mods.load('stonehearth')
local personality_service = api.personality_service

-- Copied straight from NewGameCallbackHandler.
local function place_citizen(x, z)
  local pop_service = api.population
  local faction = pop_service:get_faction("civ", "stonehearth:factions:ascendancy")
  local citizen = faction:create_new_citizen()
  faction:promote_citizen(citizen, "worker")
  radiant.terrain.place_entity(citizen, Point3(x, 1, z))
	
	-- Since we are summoning them, I am not entirely sure /how/ well that works
	radiant.events.trigger(personality_service, "stonehearth:journal_event", {
    entity = citizen,
    description = "person_embarks"
  })
end

function SummonWorkerHandler:summon_worker(session, response, standard)	
	local pos = radiant.entities.get_location_aligned(standard)
	pos.x = pos.x + math.random(-4, 4)
	pos.z = pos.z + math.random(-4, 4)
	rp.run_safe(place_citizen, pos.x, pos.z)
end

return SummonWorkerHandler
