local Callbacks = class()

Callbacks.console_chunks = {}

function Callbacks:eval_server(session, response, lua)
	local func, err = loadstring(lua)
	if not func then
		rp.log('[LuaS] [ERROR] Cannot evaluate lua: ' .. err)
		return
	end
	
	return rp.run_safe(func)
end

function Callbacks:eval_client(session, response, lua)
	local func, err = loadstring(lua)
	
	if not func then
		rp.log('[LuaC] [ERROR] Cannot evaluate lua: ' .. err)
		return
	end
	
	return rp.run_safe(func)
end

function Callbacks:get_server_logs(session, response)
	local text = table.concat(Callbacks.console_chunks, '')
	Callbacks.console_chunks = {}
	return { text = text }
end

function Callbacks:get_client_logs(session, response)
	local text = table.concat(Callbacks.console_chunks, '')
	Callbacks.console_chunks = {}
	return { text = text }
end

function Callbacks:execute_server_concommand(session, response, command, args, arg_str)
	if Callbacks.commands[command] then
		Callbacks.commands[command](command, args, arg_str)
		return { result = true }
	else
		return { result = false }
	end
end

function Callbacks:execute_client_concommand(session, response, command, args, arg_str)
	if Callbacks.commands[command] then
		Callbacks.commands[command](command, args, arg_str)
		return { result = true }
	else
		return { result = false }
	end
end

function Callbacks:selected_entity(session, response, entity)
	rawset(_G, 'SELECTED_ENTITY', entity)
	rp.log('Selected: ', entity)
	return true
end

return Callbacks