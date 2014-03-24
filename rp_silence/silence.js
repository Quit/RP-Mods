// Initialize as soon as rp is available
// (read: initialize it *now*)

var Silence = RPMod.extend({
	work : function()
	{
		rp.setCallProxy('radiant:play_music', function(data) 
			{
				if (data.track.match(/^stonehearth:/))
					return {}; 
				return radiant.native_call('radiant:play_music', data);
			}
		);
		
		this.resolve();
	}
});


rp.registerMod('rp_silence', Silence);