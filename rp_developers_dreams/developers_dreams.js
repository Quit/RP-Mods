var DD = RPMod.extend({
	work : function()
	{
		App.StonehearthLoadingScreenView = App.StonehearthLoadingScreenView.extend({
			updateProgress: function(result) {
				var self = this;

				if (result.progress) {
					self._updateMessage();
					this._progressbar.progressbar( "option", "value", result.progress );

					if (result.progress == 100) {
						radiant.call('stonehearth:embark_client')
							.done(function(o) {
								App.gotoGame();
                App.gameView._addViews(App.gameView.views.complete);
								self._rp_createCamp();
                self.destroy();
						 });
					}
				}
			},
			
			_rp_createCamp : function() { 
				var self = this;
				radiant.call('stonehearth:create_camp', { x: -3, y: 16, z: 7 }).done(function() { self._rp_createStockpile(); });
				radiant.call('rp_developers_dreams:setup_camera');
			},
				
			_rp_createStockpile : function() {
				radiant.call('rp_developers_dreams:create_stockpile', 2, 16, 6, 5, 5);
			}
		});
		
		this.resolve();
	}
});

rp.registerMod('rp_developers_dreams', DD);