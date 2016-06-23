var WorkOrderToolbarAction = function() {
  this.setupButton();
};


WorkOrderToolbarAction.prototype.setupButton = function() {
  this.$button = $(AS.renderTemplate("workOrderButtonTemplate"));

  var $btnGroup = $("<div>").addClass("btn-group");

  this.$button.appendTo($btnGroup);
  $btnGroup.appendTo($("#archives_tree_toolbar .btn-toolbar"));

  this.$button.on("click", $.proxy(this.showWorkOrderForm, this));
};


WorkOrderToolbarAction.prototype.showWorkOrderForm = function(event) {
  event.preventDefault();

  var $primary = $(".jstree-node.primary-selected:first");
  var uri = $primary.data("uri");


  var url = this.$button.attr("href");
  url += "?uri=" + uri;

  location.href = url;

  // AS.openCustomModal("workOrderModal",
  //                    this.$button.text(),
  //                    AS.renderTemplate("workOrderLoadingTemplate"),
  //                    "large",
  //                    {},
  //                    this.$button);
  //
  // new WorkOrderForm($("#workOrderModal #workOrderForm"), this);
};


var WorkOrderForm = function($container, workOrderToolbarAction) {
  this.$container = $container;
  this.workOrderToolbarAction = workOrderToolbarAction;

  this.loadForm();
};

WorkOrderForm.prototype.loadForm = function() {
  var self = this;
  var data = {};

  data.uri = [];

  $.each(AS._tree.get_selected(), function(i, nodeId) {
    var node = AS._tree.get_node(nodeId);
    data.uri.push(node.li_attr['data-uri'])
  });

  $.post(this.workOrderToolbarAction.$button.attr("href"), data, function(html) {
    self.$container.html(html);
  });
};

// if a resource tree page, setup the work order toolbar action
$(document).on("loadedrecordform.aspace", function(event, $container) {
  // are we dealing with a record with a tree?
  if ($(".archives-tree").data("read-only") || $container.is("#archives_tree_toolbar")) {
    // is the tree a resource tree?
    if (AS._tree && AS._tree.get_json()[0].type == "resource") {
      // hurray! add the button.
      new WorkOrderToolbarAction();
    }
  }
});
