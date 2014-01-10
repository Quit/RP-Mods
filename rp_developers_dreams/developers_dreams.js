var developersDreams = function()
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
					radiant.call('stonehearth:create_camp', { x: -3, y: 16, z: -7 });
					radiant.call("stonehearth:create_stockpile", { x: 2, y: 16, z: -9 }, [ 5, 5 ])
					this.destroy();
         }
      }
   },
	});
}


radiant.call('rp:init_server').done(developersDreams);