local old_write = io.write
local CH = require('callbacks')

CH.console_chunks = {}
CH.commands = {}

function io.write(...)
	old_write(...)
	local c = select('#', ...)
	
	local args = {...}
	for i = 1, c do
		table.insert(CH.console_chunks, tostring(args[i]))
	end
end

function rp.add_concommand(name, callback)
	CH.commands[name] = callback
end

rp.add_concommand('print', function(name, args, argstr)
	print(argstr)
end)

rp.add_concommand('luas_run', function(name, args, argstr)
	local func, err = loadstring(argstr)
	if not func then
		rp.log(err)
	else
		rp.run_safe(func)
	end
end)

local function selected_entity()
	return rawget(_G, 'SELECTED_ENTITY')
end

rp.add_concommand('set_scale', function(name, args, argstr)
	local se = selected_entity()
	if not se then
		error('no entity selected')
	end
	
	local size = tonumber(args[1])
	if not size or size < 0 then
		error('argument error; expected #1 to be a number >= 0')
	end
	
	se:add_component('render_info'):set_scale(size)
end)

rp.add_concommand('set_model', function(name, args, argstr)
	local se = selected_entity()
	if not se then
		error('no entity selected')
	end
	
	local name = tostring(args[1])
	if not name then
		error('expected name for argument #1')
	end
	
	se:add_component('render_info'):set_model_variant(name)
end)

return true