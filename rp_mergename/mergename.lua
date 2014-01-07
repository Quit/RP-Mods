	local faction = api.population:get_faction("civ", "stonehearth:factions:ascendancy")

	local function getRandom(names)
		return names[math.random(#names)]
	end

	function faction:generate_random_name(gender)
		local names = self._data[gender]

		local surnames = self._data.surnames
		
		return getRandomName(names.first_name_1) .. getRandom(names.first_name_2) .. ' ' .. getRandom(surnames.first_part) .. getRandom(surnames.last_part)
	end