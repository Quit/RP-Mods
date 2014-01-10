--[=============================================================================[
The MIT License (MIT)

Copyright (c) 2014 RepeatPan
excluding parts that were written by Radiant Entertainment.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]=============================================================================]

-- Config, config config config!
local CONFIG = {
	factions = {} -- factions affected by this little hack
}

CONFIG = rp.load_config(CONFIG)

-- Returns a random element from a table.
local function get_random_element(tbl)
	if not tbl then
		rp.log(debug.traceback('empty table!'))
	end
	return tbl[math.random(#tbl)]
end

-- Returns a random name from a list by trying some educated guesses.
local function get_random_name_from_list(list)
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
	
--~ local faction = population:get_faction("civ", "stonehearth:factions:ascendancy")
-- Patches "faction"
function rp.enable_alternate_name_generator(faction)
	function faction:generate_random_name(gender)
		local data = self._data
		return get_random_name_from_list(data.given_names[gender] or data.given_names._default) .. ' ' .. get_random_name_from_list(data.surnames[gender] or data.surnames._default)
	end
end

local population = api.population
-- Now, magic.
for k, entry in pairs(CONFIG.factions) do
	-- God I wish I had continue
	if type(entry) ~= 'table' then
		rp.log('[ERROR] Only objects are allowed inside CONFIG.factions')
	else
		local factionName, kingdom = entry.faction_name, entry.kingdom
		if not factionName or not kingdom then
			rp.log('[ERROR] Invalid faction entry')
		else
			local success, faction = rp.run_safe(population.get_faction, population, factionName, kingdom)
			if not success then
				rp.logf('[ERROR] Cannot find faction %q %q (%s)', tostring(factionName), tostring(kingdom), tostring(faction))
			else
				rp.enable_alternate_name_generator(faction)
				rp.logf('Successfully patched %q %q', tostring(factionName), tostring(kingdom))
			end
		end
	end
end
return true