local MOD = class()

function MOD:__init()
	radiant.events.listen(radiant.events, 'stonehearth:entity_created', self, self._on_entity_created)
end

function MOD:_on_entity_created(event)
	if event.entity_id:find('oak_tree') and not event.entity:get_component('stonehearth:placeable_item_proxy') then
		local commands = event.entity:add_component('stonehearth:commands')
		commands:add_command('/rp_diy_trees/harvest_shoot')

		event.entity:add_component('stonehearth:renewable_resource_node'):extend(
		{
			resource = "rp_diy_trees:growing_oak_tree_sapling",
			renewal_time = "12h",
			harvest_command = "harvest_shoot"
		})
		
		if event.entity:get_component('rp_diy_trees:growable') then
			commands:enable_command('harvest_shoot', false)
		end
	end
end

return MOD()