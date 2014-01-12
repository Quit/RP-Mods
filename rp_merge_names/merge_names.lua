local faction = radiant.mods.load('stonehearth').population:get_faction("civ", "stonehearth:factions:ascendancy")

local function getRandom(names)
	return names[math.random(#names)]
end

local function getRandomName(names)
	local firstName = getRandom(names)
	local secondName
	repeat
		secondName = getRandom(names)
	until secondName ~= firstName
	
	return firstName .. secondName:lower()
end

function faction:generate_random_name(gender)
	local names = self._data.given_names[gender]
	local surnames = self._data.surnames
	
	-- Re: "Could we have special names that do not follow the normal naming?"
--~ 	if math.random(#names + 1) == 1 then -- or any chance
--~ 		return getRandom(self._data.special_names)
--~ 	end
	
	-- If we had another format (as described on discourse), use this one.
--~ 		return getRandom(names.first_name_1) .. getRandom(names.first_name_2) .. ' ' .. getRandom(surnames.first_part) .. getRandom(surnames.last_part)
	return getRandomName(names) .. ' ' .. getRandomName(surnames)
end

return true