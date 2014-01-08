// ZEIT IST GELD
var timeIsMoney = function()
{
	// Do we even have to try?
	if (typeof(App.shellView) == "undefined")
	{
		// Alright, patch our screen.
		App.StonehearthTitleScreenView = App.StonehearthTitleScreenView.extend(Ember.TargetActionSupport, {
				didInsertElement: function() {
					var self = this;
					self._super();
					// as soon as it comes up, it's gone already. Magic!
					self.triggerAction({ action : 'newGame', target: self });
				}
		});
	}
	else
	{
		//App.shellView.triggerAction({ action : 'newGame', target : App.shellView });
		// ^- would like to do that, but can't
		// So: MANUAL OVERRIDE
		App.shellView.addView(App.StonehearthLoadingScreenView);
	}
	
	// In the camp...
	App.StonehearthCreateCampView = App.StonehearthCreateCampView.extend(Ember.TargetActionSupport, {
		// Immediately select the banner
		didInsertElement : function() {
			var self = this;
			self._super();
			self.triggerAction({ action : 'placeBanner', target : self  });
		},
		
		//  Immediately place the stockpile
		_gotoStockpileStep : function() {
			var self = this;
			self._super();
			self.triggerAction({ action : 'placeStockpile', target : self });
		},
		
		// YES I KNOW THAT I AM DONE
		_gotoFinishStep : function() {
			var self = this;
			self._super();
			self._finish();
		}
	});
}

radiant.call('rp:init_server').done(timeIsMoney);