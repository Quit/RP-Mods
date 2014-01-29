// Initialize as soon as rp is available
// (read: initialize it *now*)

var Silence = RPMod.extend({
	work : function()
	{
		rp.setCallProxy('radiant:play_music', function() { return {}; });
		
		this.resolve();
	}
});


rp.registerMod('rp_silence', Silence);