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
	},
	
	start_menu_hotkey = 'x'
}

CONFIG = rp.load_config(CONFIG)

local SINGLETON

 -- list of proxies that we have, entity_uri => proxy_uri
 -- I'm not exactly happy with having this as a global variable, but since they re-create
 -- the SpawnStuff...
 -- This would be a proper thing for a service, wouldn't it.
 -- Yeah, service.
 -- ... later.
local proxies = {}

function SpawnStuff:__init()
	if SINGLETON then
		SINGLETON:_destroy()
	end
	
	SINGLETON = self
end

-- Checks an item of a profession to see if it could be spawned or not
function SpawnStuff:check_professions(entity_name, entity_uri, json)
	for component_name, component in pairs(json.components) do
		if component_name:find(':workshop') then
			return component.ingredients ~= nil
		end
	end
	
	return false
end

-- Criteria: Has a unit info.
-- (that should filter out stonehearth:wolf:teeth)
function SpawnStuff:check_critters(entity_name, entity_uri, json)
	return json.components and json.components.unit_info
end

-- Criteria: Extends *placed_properties
function SpawnStuff:check_construction(entity_name, entity_uri, json)
	return json and json.mixins and json.mixins:find('placed_properties$')
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
		crafting_materials = true, -- not sure about this one.
		spawnable = true
	}
	
	local mods = {} -- table, each entry represents a mod
	
	
	-- Foreach mod...
	for modName, mod in pairs(rp.available_mods) do
		local manifest = mod.manifest
		
		-- Check if there are even entities
		if manifest.aliases then
			local modMenu = { name = manifest.info and manifest.info.name or modName, elements = {}, hotkey = self:get_hotkey(#mods), icon = manifest.info and manifest.info.icon }
			local entFolders = {}
			
			-- Foreach entity
			for entity_name, entity_uri in pairs(manifest.aliases) do
				-- Get the folder.
				local entFolder = entity_uri:match('entities/(.-)/')
				-- We're not a proxy *and* we have a folder: ding ding.
				if entFolder then
					-- Load its json, check if it's a proxy.
					local _, json = pcall(radiant.resources.load_json, entity_uri)
					json = json or {}
					local components = json.components or {}
				
					-- Get its entry from the allowed table
					local allowance = self.whitelist[entFolder] or false
				
					-- Being a proxy disqualifies.
					if components['stonehearth:placeable_item_proxy'] then
						proxies[components['stonehearth:placeable_item_proxy'].full_sized_entity] = modName .. ':' .. entity_name
						allowance = false
					elseif type(allowance) == 'function' then
						allowance = allowance(self, entity_name, entity_uri, json)
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
						
						if components.unit_info then
							json = json.components.unit_info
							-- Set our category's icon to the first icon we encounter.
							if not category.icon and json.icon then
								category.icon = json.icon
							end
						else
							json = { name = entity_name }
						end
						
						table.insert(category.elements, 
							{ 
								name = json.name, 
								icon = json.icon,
								hotkey = self:get_hotkey(#category.elements),
								click = { 
									action = 'call', 
									['function'] = 'rp_spawn_stuff:choose_spawn_location',
									args = { modName .. ':' .. entity_name, entity_uri }
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
			hotkey = CONFIG.start_menu_hotkey,
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
		if self:_shift_down() then
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
		if self:_shift_down() then
			_radiant.call('rp_spawn_stuff:choose_spawn_location', self._entity_id, self._entity_uri, self._curr_rotation)
		end
  end
  return true
end

function SpawnStuff:_shift_down()
	return _radiant.client.is_key_down(_radiant.client.KeyboardInput.KEY_LEFT_SHIFT) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.KEY_RIGHT_SHIFT)
end

function SpawnStuff:_on_keyboard_event(e)
  if e.key == _radiant.client.KeyboardInput.KEY_ESC and e.down then
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
	
	-- Post spawn: add component if necessary...
	if entity:get_component('stonehearth:placed_item') and proxies[entity_id] then
		-- Yes, this one is placeable.
		entity:get_component('stonehearth:placed_item'):extend({ proxy_entity = proxies[entity_id] })
	end
	return true
end

return SpawnStuff