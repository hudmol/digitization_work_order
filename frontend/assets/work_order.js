/* The past.  Eventually this (and the conditional below) can go away. */
var setupButtonASpace15 = function() {
  $workOrder = $(AS.renderTemplate("workOrderButtonTemplate"));

  /* ArchivesSpace 1.5.x */
  $workOrder.addClass("btn btn-xs btn-default");
  var $btnGroup = $("<div>").addClass("btn-group");

  $workOrder.appendTo($btnGroup);
  $btnGroup.appendTo($("#archives_tree_toolbar .btn-toolbar"));
};

/* The future! */
var setupButtonASpace2x = function() {
  $workOrder = $(AS.renderTemplate("workOrderButtonTemplate"));
  /* ArchivesSpace 2.x */
  $('#other-dropdown .dropdown-menu').append($('<li />').append($workOrder));
  $('#other-dropdown').show();
};


// setup the work order toolbar action
$(document).on("loadedrecordform.aspace", function(event, $container) {
  if (typeof(tree) === 'undefined') {
    if (window.location.pathname.indexOf("/resources/") >= 0) {
      setupButtonASpace15();
    }
  } else {
    if (tree && tree.current().data('jsonmodel_type') == 'resource') {
      setupButtonASpace2x();
    }
  }
});
