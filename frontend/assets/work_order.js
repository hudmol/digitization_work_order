var WorkOrderToolbarAction = function() {
  this.setupButton();
};


WorkOrderToolbarAction.prototype.setupButton = function() {
  this.$button = $(AS.renderTemplate("workOrderButtonTemplate"));

  var $btnGroup = $("<div>").addClass("btn-group");
  $btnGroup.append(this.$button);

  $(".record-toolbar .btn-toolbar.pull-right > .btn-group:first > .btn-group:first").before($btnGroup);
};


// setup the work order toolbar action
$(document).on("loadedrecordform.aspace", function(event, $container) {
  if (tree && tree.current().data('jsonmodel_type') == 'resource') {
    new WorkOrderToolbarAction();
  }
});
