// Initialize as soon as rp is available
// (read: initialize it *now*)

var Silence = RPMod.extend({
	work : function()
	{
		rp.set_call_proxy('radiant:play_music', function() { return {}; });
		
		this.resolve();
	}
});


rp.register_mod('rp_silence', Silence);