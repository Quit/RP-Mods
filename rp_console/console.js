var commands = {}; // name => function to call

rp.add_command = function(name, callback)
{
	commands[name] = callback;
}

rp.add_command('js_run', function(name, args, argstr) { eval(argstr); });

var entity_selected = function(_, data)
{
	if (data.selected_entity == null)
		return;
	
	rp.log('Selected: ', data.selected_entity);
	SELECTED_ENTITY = data.selected_entity;
	radiant.call('rp_console:selected_entity', data.selected_entity);
	$(top).off("radiant_selection_changed.rp_console");
}

rp.add_command('select_entity', function(_, _, _) {
	$(top).on("radiant_selection_changed.rp_console", entity_selected);
});

App.RpConsoleView = App.View.extend({
	templateName: 'rpConsole',
	
	target : null,
	
	inputElements : [''],
	inputIndex : 0,
	lastInputString : '',
	
	init : function()
	{
		var self = this;
		
		self._super();
		self._timer = setInterval(
			function() { 
				radiant.call('rp_console:get_server_logs').done(function(o) { self._onServerLogs(o); }).fail(rp.log);
				radiant.call('rp_console:get_client_logs').done(function(o) { self._onClientLogs(o); }).fail(rp.log);
			},
			500
		);
	},
	
	didInsertElement: function()
	{
		var self = this;
		
		self._super();
		
		$('#rpConsoleWindow').width(this._size.width).height(this._size.height);
		
		$('#rpConsoleWindow')
			.draggable(
				{
					start: function() { self._set_event_stop(true); },
					stop: function() { self._set_event_stop(false); }
				}
			)
			.resizable(
				{ 
					minWidth: $('#rpConsoleHeader').outerWidth(true), 
					resize: function(event, ui) { self._onResize(event, ui); },
					start: function() { self._set_event_stop(true); },
					stop : function() { self._set_event_stop(false); }
				}
			)
		;
		
		$('#rpConsoleInput')
			.keyup(function(e)
			{
				if (e.keyCode == 13) // TODO: Replace this with change()?
				{
					try
					{
						self._onInput($('#rpConsoleInput').val());
					}
					finally
					{
						$('#rpConsoleInput').val('');
					}
				}
				else if (e.keyCode == 38 || e.keyCode == 40) 
				{
					self.scrollInput(e.keyCode == 38 ? -1 : 1);
				}
			})
		;
		
		self.switchTarget('All');
	},
	
	_set_event_stop : function(status)
	{
		this._stop_events = status;
		radiant.call('rp:set_input_disabled', status);
	},
	
	scrollInput : function(dt)
	{
		// Is our current index 0? If so, save our state
		if (this.inputIndex == 0)
		{
			this.inputElements[0] = $('#rpConsoleInput').val();
		}
		this.inputIndex = (this.inputElements.length + this.inputIndex + dt) % this.inputElements.length;
		
		$('#rpConsoleInput').val(this.inputElements[this.inputIndex]);
	},
	
	_onServerLogs : function(data)
	{
		if (data.text.length == 0)
			return;
		
		var lines = data.text.split(/\n/);
		if (lines[lines.length-1] == '')
			lines.pop();
		
		for (var i = 0; i < lines.length; ++i)
		{
			if (lines[i].substring(20, 24) == '[JS]')
				this._addLine('Js', lines[i]);
			else
				this._addLine('LuaS', lines[i]);
		}
	},
	
	_onClientLogs : function(data)
	{
		if (data.text.length == 0)
			return;
		
		var lines = data.text.split(/\n/);
		if (lines[lines.length-1] == '')
			lines.pop();
		
		for (var i = 0; i < lines.length; ++i)
		{
			this._addLine('LuaC', lines[i]);
		}
	},
	
	_onInput : function(blob)
	{
		// Insert it anyway
		this.inputElements.push(blob);
		this.inputIndex = 0;
		
		if (this.target == null)
			return;
		
		if (this.target == 'LuaS')
		{
			this._addLine('LuaS', '>' + blob);
			radiant.call('rp_console:eval_server', blob);
		}
		else if (this.target == 'LuaC')
		{
			this._addLine('LuaC', '>' + blob);
			radiant.call('rp_console:eval_client', blob);
		}
		else if (this.target == 'Js')
		{
			this._addLine('Js', '>' + blob);
			this._addLine('Js', eval(blob));
		}
		else if (this.target == 'All')
		{
			this._executeConsoleCommand(blob);
		}
	},
	
	_executeConsoleCommand : function(blob)
	{
		// command
		// command a b c
		// command "a b" c
		// command "a b""cd" => { "a b", "cd" }, { "a b\"\"cd" }
		
		// function(name, arguments[], argString)
		// luas_run: argString; luas_run for i=1, 2 do print( "abcdef" , i) end
		// set_model "path/to model/"
		
		// set_model "foobaer\"foobarbarhjsra"
		// set_model "foobar""foobar"
		
		if (blob.match(/^\s*$/))
		{
			this._addLine('All', '');
			return;
		}
		
		var space = blob.indexOf(' ');
		if (space == -1)
			space = blob.length;
		
		var command = blob.substring(0, space);
		var argStr = blob.substring(space + 1);
		
		// radiant:event
		
		var protoArgs = argStr.split(' ');
		var args = [];
		
		var concat = null;
		
		for (var i = 0; i < protoArgs.length; ++i)
		{
			var protoArg = protoArgs[i];
			
			if (concat == null && protoArg.match(/^ *$/))
			{
				continue;
			}
			else if (concat == null && protoArg.substring(0, 1) == '"')
			{
				// arg: "foobar"
				if (protoArg.substring(protoArg.length - 1) == '"')
				{
					args.push(protoArg.substring(1, protoArg.length - 1));
					continue;
				}
				
				// arg: "foobar
				concat = protoArg.substring(1);
				continue;
			}

			else if (concat != null && protoArg.substring(protoArg.length - 1) == '"')
			{
				var quotes = protoArg.match(/("+)$/)[0].length;
				concat += ' ' + protoArg.substring(0, protoArg.length - 1);
				
				if (quotes % 2 == 1)
				{
					args.push(concat);
					concat = null;
				}
			}
			else
			{
				args.push(protoArg);
			}
		}

		// Runaway quotes		
		if (concat != null)
			args.push(concat);
		
		for (var i = 0; i < args.length; ++i)
			args[i] = args[i].replace(/""/g, '"');
		
		if (commands[command])
		{
			commands[command](command, args, argStr);
		}
		else
			radiant.call('rp_console:execute_server_concommand', command, args, argStr);
	},
	
	_addLine : function(target, text)
	{
		var lines = $('#rpConsoleLines' + target);
		lines.append(text, '\n');
		this._updateScrollPosition(lines);
		
		if (target != 'All')
			this._addLine('All', '[' + target + '] ' + text);
	},
	
	_updateScrollPosition : function(lines)
	{
		lines.scrollTop(lines[0].scrollHeight - lines.height());
	},
	
	switchTarget : function(target) {
		$('.lines').hide();
		this._updateScrollPosition($('#rpConsoleLines' + target).show());
		$('#rpConsoleHeader a.tab').removeClass('active');
		$('#rpConsoleTab' + target).addClass('active');
		this.target = target;
	},

	_size : { width: 500, height: 500 },
	
	minimize : function () {
		$('#rpConsoleInput').fadeToggle(600);
		$('#rpConsoleHeader .tab').fadeToggle('fast');
		$('#rpConsoleArea').slideToggle({ duration: 'fast', easing: 'linear' });
		
		if ($('#rpConsoleMinimizeButton').text() == '-')
		{
			this._width = $('#rpConsoleWindow').width();
			
			rp.log($('#rpConsoleWindow').outerWidth(true), $('#rpConsoleMinimizeButton').outerWidth(true));
			
			$('#rpConsoleWindow').resizable('disable').animate({ 'width' : 120, 'height' : 0, 'left' : $('#rpConsoleWindow').position().left + this._size.width - 120 }, 'fast', 'linear');
			$('#rpConsoleMinimizeButton').animate({ 'width' : 122 }, 'fast', 'linear', function() { $(this).text('Console').removeClass('minimize').addClass('maximize'); });
		}
		else
		{
			$('#rpConsoleMinimizeButton').text('-').animate({ 'width' : 50 }, 'fast', 'linear', function() { $(this).addClass('minimize').removeClass('maximize'); });
			$('#rpConsoleWindow').animate({ 'width' : this._size.width, 'height' : this._size.height, 'left' : $('#rpConsoleWindow').position().left - this._size.width + 120 }, 'fast', 'linear', function() { $(this).resizable('enable') });
		}
	},
	
	_onResize : function(event, ui)
	{
		this._size = ui.size;
	},
	
	actions : {
		switchTarget : function(target)
		{
			this.switchTarget(target);
		}
	}
});

var ConsoleMod = RPMod.extend({
	work : function()
	{
		//~ rp.log('RootView is', App.Root);
		App.rpConsoleView = App.rootView.createChildView(App.RpConsoleView);
		App.rootView.pushObject(App.rpConsoleView);
		
		//~ $('body').append('<button id="rpConsoleButton">Open Console</button>')
		//~ .click(function() { rp.log('Add View'); App.shellView.addView(App.RpConsoleView); rp.log('Added view'); })
		//~ ;
		this.resolve();
	}
});

rp.registerMod('rp_console', ConsoleMod);