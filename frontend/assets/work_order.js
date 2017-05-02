var WorkOrderToolbarAction = function() {
  this.setupButton();
};


WorkOrderToolbarAction.prototype.setupButton = function() {
   $workOrder = $(AS.renderTemplate("workOrderButtonTemplate"));

  $('#other-dropdown .dropdown-menu').append($('<li />').append($workOrder));
  $('#other-dropdown').show();
};


// setup the work order toolbar action
$(document).on("loadedrecordform.aspace", function(event, $container) {
  if (tree && tree.current().data('jsonmodel_type') == 'resource') {
    new WorkOrderToolbarAction();
  }
});
