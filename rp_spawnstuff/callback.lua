local SpawnStuff = class()

function SpawnStuff:spawn_stuff(session, request, standard, entName, entPath)
	local pos = radiant.entities.get_location_aligned(standard)
	pos.x = pos.x + math.random(0, 40) - 20
	pos.z = pos.z + math.random(0, 40) - 20
	local ent = radiant.entities.create_entity(entName)
	radiant.terrain.place_entity(ent, pos)
  radiant.entities.turn_to_face(ent, standard)	
	
--~ 	-- workshops require special attention.
--~ 	-- (that we're not going to give right now)
--~ 	local workshop_component = ent:get_component("stonehearth:workshop")
--~ 	local faction = radiant.entities.get_faction(ent)
--~		
--~ 	if workshop_component then
--~ 		local promotion_talisman_entity = workshop_component:init_from_scratch()
--~ 		ent:get_component('unit_info'):set_faction(faction)
--~ 		promotion_talisman_entity:get_component('unit_info'):set_faction(faction)
--~ 		workshop_component:associate_outbox(
--~ 	end
--~ 	local loadedJson, json = pcall(radiant.resources.load_json, entPath)
--~ 	
--~ 	if loadedJson and json and json.components then
--~ 		
--~ 	end
	return true
end

return SpawnStuff