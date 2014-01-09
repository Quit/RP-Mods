radiant.call('rp:init_server').done(function() {
	radiant.call('rp_spawnstuff:get_start_menu').done(rp.add_to_start_menu);
});