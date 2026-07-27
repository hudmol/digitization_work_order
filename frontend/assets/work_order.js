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


/* 
  setup the work order toolbar action.

  the tree variable only exists from ArchivesSpace 2.0 through 4.1.0.
  older versions don't have a tree, newer versions use infiniteTree instead.
  the code below should account for all versions
*/
$(document).on("loadedrecordform.aspace", function(event, $container) {
  if (typeof(tree) === 'undefined') {
    if (infiniteTree && infiniteTree.rootMeta.type == 'resource') {
      setupButtonASpace2x();
    } else {
      if (window.location.pathname.indexOf("/resources/") >= 0) {
        setupButtonASpace15();
      }
    }
  } else {
    if (tree && tree.current().data('jsonmodel_type') == 'resource') {
      setupButtonASpace2x();
    }
  }
});
