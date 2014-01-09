-- Hook the default standard
rp.add_entity_created_hook('stonehearth:camp_standard', function(self)
	-- And add our little command.
	local commands = self:add_component("stonehearth:commands")
	commands:add_command("/rp_workforce/commands/summon_worker")
end)

return true