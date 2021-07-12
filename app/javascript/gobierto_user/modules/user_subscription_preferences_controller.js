window.User.SubscriptionPreferencesController = (function() {
  function SubscriptionPreferencesController() {}

  SubscriptionPreferencesController.prototype.index = function(){
    _handleSiteSelected();
    _handleAreaSelected('gobierto_budget_consultations');
    _handleAreaSelected('gobierto_people');
  };

  function _handleSiteSelected(){
    $('#user_subscription_preferences_site_to_subscribe').on('change', function(){
      if ($(this).is(':checked') === false){
        _uncheckAllModuleOptions();
      } else {

        _checkAllModuleOptions();
      }
    });
  }

  function _handleAreaSelected(area_name){
    $('#user_subscription_preferences_modules_'.concat(area_name)).on('change', function(){
      if ($(this).is(':checked') === false){
        _uncheckAllAreaOptions(area_name);
      } else {
        _checkAllAreaOptions(area_name);
      }
    });
  }

  function _checkAllModuleOptions(){
    $('#modules_selection input[data-selected]').each(function(){
      $(this).prop('checked', 'checked');
      $(this).prop('disabled', true);
      _checkAllAreaOptions($(this).data('area'));
    });
  }

  function _uncheckAllModuleOptions(){
    $('#modules_selection input[data-selected]').each(function(){
      $(this).prop('disabled', false);
      if ($(this).data('selected') === false){
        $(this).prop('checked', null);
        _uncheckAllAreaOptions($(this).data('area'))
      }
    });
  }

  function _checkAllAreaOptions(area_name){
    $('#area_'.concat(area_name, ' input[data-selected]')).each(function(){
      $(this).prop('checked', 'checked');
      $(this).prop('disabled', true);
    });
  }

  function _uncheckAllAreaOptions(area_name){
    $('#area_'.concat(area_name, ' input[data-selected]')).each(function(){
      $(this).prop('disabled', false);
      if ($(this).data('selected') === false){
        $(this).prop('checked', null);
      }
    });
  }

  return SubscriptionPreferencesController;
})();

window.User.subscription_preferences_controller = new User.SubscriptionPreferencesController;
