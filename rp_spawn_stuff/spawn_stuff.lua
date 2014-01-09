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

local SpawnStuff = class()
local Point3 = _radiant.csg.Point3

local CONFIG = {
	hotkeys = {
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"a",
		"s",
		"d",
		"f",
		"g",
		"h"
	}
}

CONFIG = rp.load_config('config/spawn_stuff.json', CONFIG)

local SINGLETON

function SpawnStuff:__init()
	if SINGLETON then
		SINGLETON:_destroy()
	end
	
	SINGLETON = self
end

-- Checks an item of a profession to see if it could be spawned or not
function SpawnStuff:check_professions(entName, path)
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
function SpawnStuff:check_critters(entName, path)
	local success, json = pcall(radiant.resources.load_json, path)
	
	return success and json and json.components and json.components.unit_info
end

-- Criteria: Extends *placed_properties
function SpawnStuff:check_construction(entName, path)
	local success, json = pcall(radiant.resources.load_json, path)
	
	return success and json and json.extends and json.extends:find('placed_properties$')
end

--[[ End of helper function stuff, start of the real callback things. ]]--

-- Returns a hotkey based on a number
function SpawnStuff:get_hotkey(number)
	return CONFIG.hotkeys[number + 1]
end

-- Called by JS
function SpawnStuff:get_start_menu(session, response)
	self.whitelist = 
	{
--~ 		professions = checkProfessions, -- this doesn't work too well right now.
		construction = self.check_construction, -- wooden_door! wooden_window_frame? stockpile ...
		furniture = true,
		plants = true,
		trees = true,
		toys = true,
		critters = self.check_critters,
		ground_clutter = true,
		crafting_materials = true -- not sure about this one.
	}
	
	local mods = {} -- table, each entry represents a mod
	
	
	-- Foreach mod...
	for modName, mod in pairs(rp.available_mods) do
		local manifest = mod.manifest
		
		-- Check if there are even entities
		if manifest.radiant and manifest.radiant.entities then
			local modMenu = { name = manifest.info and manifest.info.name or modName, elements = {}, hotkey = self:get_hotkey(#mods), icon = manifest.info and manifest.info.icon }
			local entFolders = {}
			
			-- Foreach entity
			for entName, entPath in pairs(manifest.radiant.entities) do
				-- Get the folder.
				local entFolder = entPath:match('entities/(.-)/')
				-- We're not a proxy *and* we have a folder: ding ding.
				if not entName:find('_proxy$') and entFolder then
					-- Get its entry from the allowed table
					local allowance = self.whitelist[entFolder] or false
					
					if type(allowance) == 'function' then
						allowance = allowance(self, entName, entPath)
					end
					
					if allowance then
						-- Get the ent folder we're in
						local category = entFolders[entFolder]
						-- If the category does not exist, add it
						if not category then
							category = { name = entFolder, elements = {}, hotkey = self:get_hotkey(#modMenu.elements) }
							
							-- Insert and link
							entFolders[entFolder] = category
							table.insert(modMenu.elements, category)
						end
						
						local jsonAvailable, json = pcall(radiant.resources.load_json, entPath)
						if json and json.components and json.components.unit_info then
							json = json.components.unit_info
						else
							json = { name = entName }
						end
						
						table.insert(category.elements, 
							{ 
								name = json.name, 
								icon = json.icon,
								hotkey = self:get_hotkey(#category.elements),
								click = { 
									action = 'call', 
									['function'] = 'rp_spawn_stuff:choose_spawn_location',
									args = { modName .. ':' .. entName, entPath }
								} 
							}
						)
						
					end
				end
			end
			
			-- If we have found an entity...
			if #modMenu.elements > 0 then
				-- Add a mod, I guess
				table.insert(mods, modMenu)
			end
		end
	end
	
	return
	{
		{
			name = 'Spawn',
			hotkey = 'x',
			icon = '/rp_spawn_stuff/spawn_stuff.png',
			elements = mods
		}
	}
end

function SpawnStuff:choose_spawn_location(session, response, entity_id, entity_uri, rotation)
	self._entity_id = entity_id
	self._entity_uri = entity_uri
	self._cursor_entity = self._cursor_entity or radiant.entities.create_entity(entity_uri)
  local re = _radiant.client.create_render_entity(1, self._cursor_entity)
  self._cursor_entity:add_component("render_info"):set_material("materials/ghost_item.xml")
  self._curr_rotation = rotation or 0
	self._cursor_entity:add_component("mob"):turn_to(self._curr_rotation + 180)
  self._capture = _radiant.client.capture_input()
  self._capture:on_input(function(e)
    if e.type == _radiant.client.Input.MOUSE then
      self:_on_mouse_event(e.mouse, response)
      return true
    end
    if e.type == _radiant.client.Input.KEYBOARD then
      self:_on_keyboard_event(e.keyboard)
    end
    return false
  end)
end

function SpawnStuff:_on_mouse_event(e, response)
  local s = _radiant.client.query_scene(e.x, e.y)
  local pt = s.location and s.location or Point3(0, -100000, 0)
  pt.y = pt.y + 1
  self._cursor_entity:add_component("mob"):set_location_grid_aligned(pt)
  
	if e:up(2) and s.location then
    local inc = 90
		-- Shift turns 15° instead of 90
		if _radiant.client.is_key_down(_radiant.client.KeyboardInput.LEFT_SHIFT) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.RIGHT_SHIFT) then
			inc = 15
		end
		
		self._curr_rotation = (self._curr_rotation + inc) % 360
    self._cursor_entity:add_component("mob"):turn_to(self._curr_rotation + 180)
  end
	
  if e:up(1) and s.location then
		_radiant.call('radiant:play_sound', 'stonehearth:sounds:place_structure')
    _radiant.call('rp_spawn_stuff:spawn_stuff', self._entity_id, self._entity_uri, pt, self._curr_rotation + 180):done(function(result)
      response:resolve(result)
    end):fail(function(result)
      response:reject(result)
    end):always(function()
      self:_destroy()
    end)
		
		-- ... again?
		if _radiant.client.is_key_down(_radiant.client.KeyboardInput.LEFT_SHIFT) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.RIGHT_SHIFT) then
			_radiant.call('rp_spawn_stuff:choose_spawn_location', self._entity_id, self._entity_uri, self._curr_rotation)
		end
  end
  return true
end

function SpawnStuff:_on_keyboard_event(e)
  if e.key == _radiant.client.KeyboardInput.ESC and e.down then
    self:_destroy()
	end
  return false
end

function SpawnStuff:_destroy_capture()
	if self._capture then
		self._capture:destroy()
		self._capture = nil
	end
end

function SpawnStuff:_destroy()
	if radiant.check.is_entity(self._cursor_entity) then
		_radiant.client.destroy_authoring_entity(self._cursor_entity:get_id())
	end
		
	self:_destroy_capture()
		
	if SINGLETON == self then
		SINGLETON = nil
	end
end
	
function SpawnStuff:spawn_stuff(session, response, entity_id, entity_uri, location, rotation)
	local entity = radiant.entities.create_entity(entity_id)
	radiant.terrain.place_entity(entity, location)
	radiant.entities.turn_to(entity, rotation)
	
	return true
end

return SpawnStuff