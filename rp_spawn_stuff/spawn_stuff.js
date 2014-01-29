var SpawnStuff = RPMod.extend({
	work : function()
	{
		var self = this;
		radiant.call('rp_spawn_stuff:get_start_menu').done(function(o) { rp.addToStartMenu(o); self.resolve(); });
	}
});

rp.registerMod('rp_spawn_stuff', SpawnStuff);