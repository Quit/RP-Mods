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

local Sapling = class()

function Sapling:__init(entity, data)
	self._entity = entity
	self._render_info = entity:add_component('render_info')
	self._stage, self._ticks = 1, 0
	self._model_variant = ''
	
	radiant.events.listen(entity, 'stonehearth:renewable_resource_spawned', self, self._on_renewable_resource_spawned)
	
	-- Per default, we're not harvestable
	local commands = entity:add_component('stonehearth:commands')
	commands:enable_command('harvest_shoot', false)
	
	self:check_chop()
	self._copying_components = { 'stonehearth:resource_node', 'unit_info' }
	
	radiant.entities.on_destroy(entity, function() if self._timer then self._timer:stop() end end)
end

function Sapling:extend(json)
	-- Load whatever is necessary here.
	self._stages = json.stages
	assert(self._stages)
	
	self._current_stage = self._stages[1]
	
	self:_set_timer()
end

function Sapling:_set_timer()
	if self._current_stage.duration then
		self._timer = rp.create_timer(self, self._current_stage.duration, 1, self.grow, self)
	end	
end

-- returns whether this sapling can still grow
function Sapling:is_fully_grown()
	return self._stage >= #self._stages
end

function Sapling:grow()
	assert(not self:is_fully_grown(), "cannot grow to next stage; there is no next stage")
	
	-- Update our stage
	self._stage = self._stage + 1
	local current_stage = self._stages[self._stage]
	self._current_stage = current_stage
	
	-- Adapt us, if necessary
	if current_stage.model_variant then
		self._render_info:set_model_variant(current_stage.model_variant)
		self._model_variant = current_stage.model_variant
	end
	
	-- If we have new resource info, add it
	for _, component in pairs(self._copying_components) do
		if current_stage[component] then
			self._entity:add_component(component):extend(current_stage[component])
		end
	end
	
	-- Special-ish: render_info
	if current_stage.render_info then
		if current_stage.render_info.scale then
			self._render_info:set_scale(current_stage.render_info.scale)
		end
	end
	
	-- Effect?
	if current_stage.growth_effect then
		radiant.effects.run_effect(self._entity, current_stage.growth_effect)
	end
	
	-- Was a call requested?
	if current_stage.on_start then
		local call = current_stage.on_start
		assert(call.name)
		local args = call.args or {}
		
		for k, v in pairs(args) do
			if v == '{{self}}' then
				args[k] = self
			elseif v == '{{entity}}' then
				args[k] = self._entity
			end
		end
		
		if call.action == 'call' then
			_radiant.call(call.name, args)
		else
			error('invalid on_start; action not call')
		end
	end
	
	-- Check if we're choppable
	self:check_chop()
	
	-- Restart the timer?
	if not self:is_fully_grown() then
		self:_set_timer()
	else
		self._timer = nil
	end
end

function Sapling:_on_renewable_resource_spawned()
	-- Re-set our model.
	self._render_info:set_model_variant(self._model_variant)
end

function Sapling:check_chop()
	local resource_node = self._entity:get_component('stonehearth:resource_node')
	self._entity:get_component('stonehearth:commands'):enable_command('chop', resource_node and resource_node._durability > 0)
end

return Sapling