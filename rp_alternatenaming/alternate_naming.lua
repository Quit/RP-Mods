local population = api.population
local faction = population:get_faction("civ", "rp_alternatenaming:factions:ascendies")

-- Step 1: Patch population.
do
	local old_get_faction = population.get_faction
	
	function population:get_faction(faction, kingdom)
		-- If the original ascendancy has been requested
		if kingdom == 'stonehearth:factions:ascendancy' then
			-- then long live the king.
			kingdom = 'rp_alternatenaming:factions:ascendies'
		end
		
		return old_get_faction(self, faction, kingdom)
	end
	-- (I should probably add some sort of rp hook for that..?)
end

--Step 2: Modify our faction so ascendies behave a little bit different.

-- Returns a random element from a table.
local function get_random_element(tbl)
	if not tbl then
		rp.log(debug.traceback('empty table!'))
	end
	return tbl[math.random(#tbl)]
end

-- Returns a random name from a list by trying some educated guesses.
function faction:get_random_name_from_list(list)
--~ 	PrintTable(list)
	-- Asser that our list isn't empty.
	assert(#list > 0, "get_random_name_from_list cannot operate on an empty list")
	
	-- Check if we have either a string or a table as first index
	if type(list[1]) == 'table' then
		-- We have to do the ugly one.
		
		-- List that will contain each part
		local t = {}
		
		-- How many parts there are
		local count = #list
		
		for i = 1, count do
			local sub_list = list[i]
			-- If the sub-list (part?) is defining a chance, evaluate it
			if not sub_list.chance or math.random(100) <= sub_list.chance then
				-- Insert it into the list of parts.
				table.insert(t, get_random_element(sub_list.list)) -- my god I was horrible at naming
			end
		end
		
		-- Return the glued-together list of word parts. That should make a word. Hopefully.
		return table.concat(t, '')
	else
		-- A "normal" list.
		return get_random_element(list)
	end
end

function faction:generate_random_name(gender)
	local data = self._data
	return self:get_random_name_from_list(data.given_names[gender] or data.given_names._default) .. ' ' .. self:get_random_name_from_list(data.surnames[gender] or data.surnames._default)
end