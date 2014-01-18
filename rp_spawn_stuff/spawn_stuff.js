var SpawnStuff = RPMod.extend({
	work : function()
	{
		var self = this;
		radiant.call('rp_spawn_stuff:get_start_menu').done(function(o) { rp.add_to_start_menu(o); self.resolve(); });
	}
});

rp.register_mod('rp_spawn_stuff', SpawnStuff);