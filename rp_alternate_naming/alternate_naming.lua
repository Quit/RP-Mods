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


--[[ Helper functions ]]--
-- Returns a random element from a table.
local function get_random_element(tbl)
	if not tbl then
		rp.log(debug.traceback('empty table!'))
	end
	return tbl[math.random(#tbl)]
end

-- Returns a random name from a list by trying some educated guesses.
local function get_random_name_part_from_list(list, gender)
	list = list[gender] or list._default
	
	-- Asser that our list isn't empty.
	local parts = list.parts or list
	assert(#parts > 0, "get_random_name_from_list cannot operate on an empty list")
	
	-- Check if we have either a string or a table as first index
	if type(parts[1]) == 'table' then
		-- We have to do the ugly one.
		
		-- List that will contain each part
		local t = {}
		
		-- How many parts there are
		local count = #parts
		
		for i = 1, count do
			local sub_list = parts[i]
			-- If the sub-list (part?) is defining a chance, evaluate it
			if not sub_list.chance or math.random(100) <= sub_list.chance then
				-- Insert it into the list of parts.
				table.insert(t, get_random_element(sub_list.list)) -- my god I was horrible at naming
			end
		end
		
		local result = table.concat(t, '')
		
		if list.replacements then
			for _, replace in pairs(list.replacements) do
				result = result:gsub(replace[1], replace[2])
			end
		end
		
		-- Return the glued-together list of word parts. That should make a word. Hopefully.
		return result
	else
		-- A "normal" list.
		return get_random_element(parts)
	end
end

local function get_random_name_from_list(list, gender)
	return get_random_name_part_from_list(list.given_names, gender) .. ' ' .. get_random_name_part_from_list(list.surnames, gender)
end

-- Returns a function that we can abuse for hooks.
-- It's worse than the OOP approach, I suppose, but I like it more. It's not creating useless classes.
local function get_propose_function(json, priority)
	return function(faction, event) table.insert(event.proposals, { name = get_random_name_from_list(json, event.gender), priority = priority }) end
end

--[[ The mod itself ]]
local MOD = class()

function MOD:__init()
	self:_load_config()
	radiant.events.listen(radiant.events, 'rp:faction_created', self, self._on_faction_created)
end

function MOD:_load_config()
	-- Config, config config config!
	self._factions = {}
	for _, entry in pairs(rp.load_config({ factions = {}}).factions) do
		local _, json = pcall(radiant.resources.load_json, entry.kingdom)
		
		if type(entry.priority) ~= 'number' or not json or not entry.faction_name then
			rp.logf('Invalid entry for faction %q: No valid kingdom/priority found', tostring(entry.faction_name))
		else
			entry.kingdom_json = json
			self._factions[entry.faction_name] = entry
			
			-- Was dump specified?
			if type(entry.dump) == 'number' and io then
				-- Dump a few entries I guess.
				local filename = entry.kingdom:gsub('[^A-Za-z]', '_'):gsub('_+', '_') .. ".txt"
				rp.logf('Dumping %d entries for %q to %s:', entry.dump, entry.faction_name, filename)
				
				local file = io.open(filename, 'w')
				
				for i = 1, entry.dump do
					local gender = (i % 2 == 0) and 'male' or 'female'
					file:write(string.format('[% 6s]\t%s\n', gender, get_random_name_from_list(entry.kingdom_json, gender)))
				end
				
				file:close()
			end
		end
	end
end

function MOD:_on_faction_created(event)
	-- Do we have this faction in our table?
	if self._factions[event.faction] then
		local data = self._factions[event.faction]
		
		-- Listen to the events and provide useful names.
		radiant.events.listen(event.object, 'rp:propose_citizen_name', event.object, get_propose_function(data.kingdom_json, data.priority))
	end
end

return MOD()