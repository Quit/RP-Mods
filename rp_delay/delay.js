var Delay = RPMod.extend({
	_i : 0,
	
	work : function()
	{
		this.doWork();
	},
	
	doWork : function()
	{
		var self = this;
		
		if (++self._i == 100)
		{
			self.resolve();
			return;
		}
		
		self.notify((Math.sin(self._i / 10) + 1) * 50);
		
		setTimeout(function() { self.doWork(); }, 100);
	}
	
});

rp.register_mod('rp_delay', Delay);