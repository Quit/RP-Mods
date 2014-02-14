// ZEIT IST GELD
var TIM = RPMod.extend({
	work : function()
	{
		// Alright, patch our screen.
		App.StonehearthTitleScreenView = App.StonehearthTitleScreenView.extend(Ember.TargetActionSupport, {
				didInsertElement: function() {
					var self = this;
					self._super();
					// as soon as it comes up, it's gone already. Magic!
					self.triggerAction({ action : 'quickStart', target: self });
				}
		});
		
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
		
		this.resolve();
	}
});

rp.registerMod('rp_time_is_money', TIM);