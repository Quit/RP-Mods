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
						App.gotoGame();
						//~ App.gameView.addView(App.StonehearthCreateCampView);
						App.gameView._addViews(App.gameView.views.complete);
						self._rp_createCamp();
					}
				}
			},
			
			_rp_createCamp : function() { 
				var self = this;
				radiant.call('stonehearth:create_camp', { x: -3, y: 16, z: 7 }).done(function() { self._rp_createStockpile(); });
			},
				
			_rp_createStockpile : function() {
				radiant.call('stonehearth:create_stockpile', { x: 2, y: 16, z: 6 }, [ 5, 5 ]);
			}
		});
		
		this.resolve();
	}
});

rp.register_mod('rp_developers_dreams', DD);