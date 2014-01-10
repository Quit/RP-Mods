local population = api.population

local CONFIG = { 
	replacements = {  -- faction_name => { faction_name = "another faction name, or the same", kingdom = "another kingdom name, or the same" } } replacement file/kingdom... whatever :X
--~ 		["civ"] = { kingdom = "rp_alternatenaming:factions:ascendies" }
	}
}

CONFIG = rp.load_config(CONFIG)

-- original faction name => replacement faction object
local factionReplacements = {}

-- I'm allowed to add functions to rp. This might get merged into rp's core at some point, we will have to see.
-- rp.set_faction_proxy(factionName, newKingdom)
function rp.set_faction_proxy(factionName, newFaction)
	factionReplacements[factionName] = newFaction
end

-- Try to load the factions
for faction_name, replacement in pairs(CONFIG.replacements) do
	if type(replacement) ~= 'table' then
		rp.logf('[ERROR] Expected object in CONFIG.replacements but got %s', type(replacement))
	else
		local new_faction = replacement.faction_name or faction_name
		local new_kingdom = replacement.kingdom
		
		if not new_kingdom then
			rp.logf('[ERROR] New kingdom needs to be set for %q (-> %q)', faction_name, new_faction)
		else
			local success, faction = rp.run_safe(population.get_faction, population, replacement.faction_name or faction_name, replacement.kingdom)
			
			if success then
				rp.set_faction_proxy(faction_name, faction)
				rp.logf("Successfully redirecting %q to %q %q", faction_name, new_faction, new_kingdom)
			else
				rp.logf("Cannot redirect %q to %q (file not found/json error?)", faction, kingdom)
			end
		end
	end
end

-- Patch population.
do
	local old_get_faction = population.get_faction
	
	function population:get_faction(faction, kingdom)
		return factionReplacements[faction] or old_get_faction(self, faction, kingdom)
	end
end

return true
