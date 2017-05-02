var WorkOrderToolbarAction = function() {
  this.setupButton();
};


WorkOrderToolbarAction.prototype.setupButton = function() {
   $workOrder = $(AS.renderTemplate("workOrderButtonTemplate"));

  if ($('#other-dropdown .dropdown-menu').length > 0) {
    /* ArchivesSpace 2.x */
    $('#other-dropdown .dropdown-menu').append($('<li />').append($workOrder));
    $('#other-dropdown').show();
  } else {
    /* ArchivesSpace 1.5.x */
    $workOrder.addClass("btn btn-sm btn-default");
    var $btnGroup = $("<div>").addClass("btn-group");

    $workOrder.appendTo($btnGroup);
    $btnGroup.appendTo($("#archives_tree_toolbar .btn-toolbar"));
  }
};


// setup the work order toolbar action
$(document).on("loadedrecordform.aspace", function(event, $container) {
  if (tree && tree.current().data('jsonmodel_type') == 'resource') {
    new WorkOrderToolbarAction();
  }
});
