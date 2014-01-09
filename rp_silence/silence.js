// Initialize as soon as rp is available
// (read: initialize it *now*)
radiant.call('rp:init_server').done(function()
{
	// Make sure "nothing" plays.
	// Wait one tick because I HAVE NO IDEA.
	setTimeout(function() {
		radiant.call('radiant:play_music', {
            'track': 'rp_silence:music:silence',
            'channel' : 'bgm',
						'volume': 0
		});
		
		rp.set_call_proxy('radiant:play_music', function() { /* no, no, music afuera */ return {}; });
		
		}, 0);
});