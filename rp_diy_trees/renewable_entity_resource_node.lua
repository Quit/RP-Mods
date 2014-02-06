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

local calendar_service = radiant.mods.load('stonehearth').api
local Vec3 = _radiant.csg.Point3f

local Node = class()

function Node:__init(entity, data)
	self._entity = entity
	self._mob = entity:add_component('mob')
	self._spawned_entities = {}
	
	radiant.entities.on_destroy(entity, function() if self._timer then self._timer:stop() end end)
end

function Node:extend(json)
	-- Load whatever is necessary here.
	local data = radiant.resources.load_json(json.data_file)
	
	self._entity_name = data.entity
	self._entity_locations = data.locations[self._entity:get_uri()]
	
	self:spawn_resource()
	
	if data.command then
		local commands = entity:add_component('stonehearth:commands')
		commands.add_command(data.command)
	end
	
--~ 	self:_set_timer()
end

function Node:remove_resource()
	for k, v in pairs(self._spawned_entities) do
		radiant.entities.destroy_entity(v)
	end
	
	self._spawned_entities = {}
end

function Node:spawn_resource()
	self:remove_resource()
	
	local mob = self._mob
	local pos = mob:get_world_location()
	local rot = mob:get_rotation()
	
	for k, v in pairs(self._entity_locations) do
		local ent = radiant.entities.create_entity(self._entity_name)
		local loc = pos + rot:rotate(Vec3(unpack(v)))
		radiant.terrain.place_entity(ent)
		radiant.entities.turn_to(ent, 0)
		ent:get_component('mob'):move_to(loc)
		table.insert(self._spawned_entities, ent)
	end
end

return Node