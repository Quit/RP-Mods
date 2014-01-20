local CAC = class()

-- The kind-of-legal part
local COMMANDS = { 
	["stonehearth:harvest_tree"] = true,
	["stonehearth:harvest_plant"] = true
}

-- The legal part
function CAC:harvest(session, response, entity, ...)
	if not entity then
		return
	end
	
	local commands = entity:get_component('stonehearth:commands')
	
	if commands then
		-- Wish we had a better way of doing this.
		for k, command in pairs(commands._data.commands) do
			if COMMANDS[command["function"]] then
				-- Make sure this harvest command is enabled
				if not command.enabled then
					return nil
				end
				
				return { command = command["function"] }
			end
		end
	end
	
	return nil
end

return CAC