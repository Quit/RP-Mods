radiant.call('rp:init_server').done(function() {
	radiant.call('rp_spawn_stuff:get_start_menu').done(rp.add_to_start_menu);
});