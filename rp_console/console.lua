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

-- TODO: Perhaps instead of doing this global, try to
-- insert this into the fenv that we call from JS?
local function selected_entity()
	return rawget(_G, 'SELECTED_ENTITY')
end

-- Adds a new command which will receive (name, args, argstr)
function rp.add_concommand(name, callback)
	if type(name) ~= 'table' then
		name = { name }
	end
	
	for k, v in pairs(name) do
		CH.commands[v] = callback
	end
end

-- Adds a new command that validates for selected_entity and receives (name, entity, args, argstr)
function rp.add_entity_concommand(name, callback)
	rp.add_concommand(name, function(name, args, argstr)
		local se = selected_entity()
		if not se or not radiant.check.is_entity(se) then
			error('no entity selected')
		end
		
		return callback(name, se, args, argstr)
	end)
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

rp.add_entity_concommand({ 'set_scale', 'ss' }, function(name, se, args, argstr)
	local size = tonumber(args[1])
	if not size or size < 0 then
		error('argument error; expected #1 to be a number >= 0')
	end
	
	se:add_component('render_info'):set_scale(size)
end)

rp.add_entity_concommand({ 'set_model', 'sm' }, function(name, se, args, argstr)
	local name = tostring(args[1])
	if not name then
		error('expected name for argument #1')
	end
	
	se:add_component('render_info'):set_model_variant(name)
end)

rp.add_entity_concommand({ 'destroy_entity', 'de' }, function(name, se, args, argstr)
	radiant.entities.destroy_entity(se)
end)

rp.add_entity_concommand({ 'set_pos', 'sp' }, function(name, se, args, argstr)
	local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
	
	if not x or not y or not z then
		error('invalid coordinates')
	end
	
	se:add_component('mob'):move_to(x, y, z)
end)
return true