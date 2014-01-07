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

-- Checks an item of a profession to see if it could be spawned or not
local function checkProfessions(entName, path)
	local success, json = pcall(radiant.resources.load_json, path)
	
	if not success or not json or not json.components then
		return false
	end

	for componentName, component in pairs(json.components) do
		if componentName:find(':workshop') then
			return component.ingredients ~= nil
		end
	end
	
	return false
end

-- Criteria: Has a unit info.
-- (that should filter out stonehearth:wolf:teeth)
local function checkCritters(entName, path)
	local success, json = pcall(radiant.resources.load_json, path)
	
	return success and json and json.components and json.components.unit_info
end

-- Criteria: Extends *placed_properties
local function checkConstruction(entName, path)
	local success, json = pcall(radiant.resources.load_json, path)
	
	return success and json and json.extends and json.extends:find('placed_properties$')
end

-- Entities in said folders (i.e. entities/[whitelist]/) will be included.
-- If the value is a function, the result of func(entName, entPath) will be used.
local whitelist = 
{
--~ 	professions = checkProfessions, -- this doesn't work too well right now.
	construction = checkConstruction, -- wooden_door! wooden_window_frame? stockpile ...
	furniture = true,
	plants = true,
	trees = true,
	toys = true,
	critters = checkCritters,
	ground_clutter = true,
	crafting_materials = true -- not sure about this one.
}

-- List of entities that can be spawned.
local spawnableEnts = {}

-- Foreach mod...
for modName, mod in pairs(rp.available_mods) do
	local manifest = mod.manifest
	
	-- Check if there are even entities
	if manifest.radiant and manifest.radiant.entities then
		-- Foreach entity
		for entName, path in pairs(manifest.radiant.entities) do
			-- Get the folder.
			local entFolder = path:match('entities/(.-)/')
			-- We're not a proxy *and* we have a folder: ding ding.
			if not entName:find('_proxy$') and entFolder then
				-- Get its entry from the allowed table
				local allowance = whitelist[entFolder] or false
				
				if type(allowance) == 'function' then
					allowance = allowance(entName, path)
				end
				
				if allowance then
					spawnableEnts[modName .. ':' .. entName] = path
				end
			end
		end
	end
end

-- Does magic.
local function addItems(standard)
	local commands = standard:add_component("stonehearth:commands")
	
	for entName, entPath in pairs(spawnableEnts) do
		local command = commands:add_command('/rp_spawnstuff/spawn_stuff')
		local jsonAvailable, json = pcall(radiant.resources.load_json, entPath)
		local unit_info = json and json.components and json.components.unit_info
		
		if unit_info then
			command.tooltip = unit_info.name or entName
			command.icon = unit_info.icon or command.icon
		else
			command.tooltip = entName
		end
		
		command.args = { standard, entName, entPath }
	end
end

rp.add_entity_created_hook('stonehearth:camp_standard', addItems)