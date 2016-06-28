(function(exports) {

    var flattenTree = function (tree, level) {
        if (level === undefined) {
            level = 0;
        }

        var root = {'uri': tree.uri, 'title': tree.title, 'level': level, 'selected': false};

        var result = [root]

        if (tree['children'] && tree['children'].length > 0) {
            root['children'] = true
            for (var i = 0; i < tree['children'].length; i++) {
                result = result.concat(flattenTree(tree['children'][i], level + 1));
            }
        }

        return result;
    };

    var getIndexForUri = function(tree, uri) {
        var index;

        $.each(tree, function(i, record) {
            if (record.uri == uri) {
                index = i;
                return false
            }
        });

        if (index == null) {
            throw "uri not found in tree: " + uri;
        }

        return index;
    }


    var filterTree = function (tree) {
        /* A stack of the ancestry of the current element.  For example, a
           record four levels of nesting deep will have an ancestry of [0, 1, 2,
           3], since its parent was three levels deep, its grandparent was two
           levels, and so on. */
        var ancestorLevels = [];

        return tree.filter(function (elt) {
            /* Wind back our list of ancestors to find the parent of the
               current record.  If we go from level 5 to level 2, we've moved
               back up the tree a couple of steps and need to discard those
               entries. */
            while (ancestorLevels[ancestorLevels.length - 1] >= elt.level) {
                ancestorLevels.pop();
            }

            /* If the current record is selected, or if its parent was, we keep it.
               Additionally, the root node is always kept. */
            var keepRecord = (elt['level'] == 0 ||
                              elt['selected'] ||
                              (elt['level'] - 1) === ancestorLevels[ancestorLevels.length - 1]);

            /* If the current record met the criteria, record it so its children
               are also kept. */
            if (elt['level'] == 0 || elt['selected']) {
                ancestorLevels.push(elt['level'])
            }

            return keepRecord;
        });
    };


    var renderTable = function (tree) {

        var parents_selected = [tree[0]['selected']];
        var level = tree[0]['level'];

        // We only want to keep nodes that are either: the root node, selected, the immediate child of a selected node
        var filtered_tree = filterTree(tree);

        var selected_count = filtered_tree.filter(function (elt) { return elt['selected']; }).length;

        $("#selectedCount").html(selected_count);
        $("#generateWorkOrderReport").prop("disabled", selected_count == 0);

        $("#work_order_table").empty();

        var tableData = new fattable.SyncTableModel();
        tableData.getCellSync = function(i,j) {
            if (i >= filtered_tree.length) {
                return {
                    'content': '',
                    'rowId': i,
                };
            }

            if (j === 0) {
                return {
                    "content": "<label class='work-order-checkbox-label'><input data-rowid='"+ i +"' id='item"+i+"' value='"+filtered_tree[i]['uri']+"' type='checkbox' " + (filtered_tree[i]['selected'] ? "checked" : "") + " /></label>",
                    "rowId": i,
                }
            }

            var spaces = '';

            for (var space = 0; space < filtered_tree[i]['level']; space++) {
                spaces += '<span class="work-order-space"></span>';
            }

            var content = '<label class="work-order-label" for="item'+i+'">' + spaces + filtered_tree[i]['title'] + '</label>';

            if (filtered_tree[i]['children']) {
                content = '<span class="work-order-has-children">' + content + '</span>';
            }

            return {
                "content": content,
                "rowId": i
            }
        };

        tableData.getHeaderSync = function(j) {
            if (j == 0) {
                return "Selected";
            } else if (j == 1) {
                return "Record Title";
            } else {
                return "Col" + j;
            }
        }

        var painter = new fattable.Painter();
        painter.fillCell = function(cellDiv, data) {
            cellDiv.innerHTML = data.content;
            if (data.rowId % 2 == 0) {
                cellDiv.className = "even";
            }
            else {
                cellDiv.className = "odd";
            }
        }
        painter.fillCellPending = function(cellDiv, data) {
            cellDiv.textContent = "";
            cellDiv.className = "pending";
        }

        var ROW_HEIGHT = 35;

        var table = fattable({
            "container": "#work_order_table",
            "model": tableData,
            "nbRows": filtered_tree.length,
            "rowHeight": ROW_HEIGHT,
            "headerHeight": 40,
            "painter": painter,
            "columnWidths": [100, 4500]
        });

        var idealHeight = ROW_HEIGHT * (filtered_tree.length + 1) + 20;
        $("#work_order_table").height(Math.min($("#work_order_table").height(), idealHeight));

        window.onresize = function() {
            table.setup();
        }

        return table;
    }

    exports.initWorkOrderTable = function (tree, report_url) {
        var flattened = flattenTree(tree);

        workOrderFatTable = renderTable(flattened);

        $("#work_order_table").on("click", ":input", function(event) {
            var $checkbox = $(event.target);

            var rowid = parseInt($checkbox.data("rowid"));
            var uri = $checkbox.val();

            // update record 'selected' state
            var index = getIndexForUri(flattened, uri);
            flattened[index].selected = $checkbox.is(":checked");

            // update all children
            var level = flattened[index].level;
            for (var i = index + 1; i < flattened.length; i++) {
                if (flattened[i].level > level) {
                    flattened[i].selected = $checkbox.is(":checked");
                } else {
                    break;
                }
            }

            var offsetTop = workOrderFatTable.scroll.scrollTop;

            console.log(flattened);
            workOrderFatTable = renderTable(flattened);

            // navigate back to the row you just clicked
            workOrderFatTable.goTo(rowid, 0);
            workOrderFatTable.scroll.setScrollXY(0, offsetTop);
        });

        $("#generateWorkOrderReport").on("click", function() {
            var selected = [];
            $.each(flattened, function(i, elt) {
                if (elt['selected']) {
                    selected.push(elt['uri']);
                }
            });

            console.log("vvvvvvvv SELECTED URIS: vvvvvvvv");
            console.log(selected);


            $.post(report_url, {
                selected: selected
            }, function(data) {
                console.log(data);
            });

            console.log("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
        });
    };
})(window);
