var MOD = RPMod.extend({
	enabled : false,
	
	work : function()
	{
		var self = this;

		// Add us to the menu
		rp.add_to_start_menu([
			{
				name : "Harvest",
				hotkey : 'h',
				icon : '/rp_click_and_gone/menu_icon.png',
				click : function(a, b, c) { self.enableHarvest(); }
			}
		]);
			
		self.resolve();
	},
	
	enableHarvest : function()
	{
		var self = this;
		// Make sure that all events are off, otherwise multi-harvesting might occur
		self.disableHarvest();
		
		$(top).on("radiant_selection_changed.rp_click_and_gone", function(_, data) { self._onHarvest(data); });
		$(top).on("keyup.rp_click_and_gone", function(event) { self._onKeyup(event); });
		$(top).trigger('radiant_show_tip', { 
			title : 'Click trees and berry bushes to harvest them',
      description : 'Click on any tree or berry bush to mark them for harvest.'
		});
		
		App.gameView.getView(App.StonehearthUnitFrameView).supressSelection(true);
	},
	
	disableHarvest : function()
	{
		$(top).off('.rp_click_and_gone');
		$(top).trigger('radiant_hide_tip');
		App.gameView.getView(App.StonehearthUnitFrameView).supressSelection(false);
	},
	
	_onHarvest : function(data)
	{
		if (data.selected_entity)
			radiant.call('rp_click_and_gone:harvest', data.selected_entity).done(function(o) { 
				if (o) 
				{
					radiant.call(o.command, data.selected_entity); 
					radiant.call('radiant:play_sound', 'stonehearth:sounds:ui:action_click');
				}
			});
	},
	
	_onKeyup : function(event)
	{
		// Escape
		if (event.keyCode == 27)
			this.disableHarvest();
	}
});


rp.register_mod('rp_click_and_gone', MOD);