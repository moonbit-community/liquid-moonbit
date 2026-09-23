///|
fn render_table_row(
  loop_var : String,
  collection : Expr,
  body : Array[RenderNode],
  cols : Int,
  context : LiquidContext,
  state : RenderState,
) -> String {
  match collection.eval(context, state) {
    Array(items) => {
      if cols <= 0 {
        return render_error(state, "Table row columns must be positive")
      }
      let saved_item = context.variables.get(loop_var)
      let saved_loop = context.variables.get("tablerowloop")
      state.loops += 1
      let mut output = "<table>\n"
      let mut index = 0
      let mut row_open = false
      for item in items {
        // Start new row if needed
        if index % cols == 0 {
          if row_open {
            output = output + "</tr>\n"
          }
          output = output + "<tr>\n"
          row_open = true
        }

        // Create tablerow context with tablerowloop object
        let loop_context = context
        loop_context.set(loop_var, item)

        // Set enhanced tablerowloop object properties
        let tablerowloop_obj = Map([])
        tablerowloop_obj.set("index", number_value((index + 1).to_double()))
        tablerowloop_obj.set("index0", number_value(index.to_double()))
        tablerowloop_obj.set(
          "col",
          number_value((index % cols + 1).to_double()),
        )
        tablerowloop_obj.set("col0", number_value((index % cols).to_double()))
        tablerowloop_obj.set("first", bool_value(index == 0))
        tablerowloop_obj.set("last", bool_value(index == items.length() - 1))
        tablerowloop_obj.set("length", number_value(items.length().to_double()))

        // Enhanced tablerowloop properties
        tablerowloop_obj.set("col_first", bool_value(index % cols == 0))
        tablerowloop_obj.set("col_last", bool_value(index % cols == cols - 1))
        tablerowloop_obj.set(
          "rindex",
          number_value((items.length() - index).to_double()),
        )
        tablerowloop_obj.set(
          "rindex0",
          number_value((items.length() - index - 1).to_double()),
        )
        loop_context.set("tablerowloop", object_value(tablerowloop_obj))
        output = output + "<td>"
        for body_node in body {
          output = output + render_node_inner(body_node, loop_context, state)
        }
        output = output + "</td>\n"
        let flow = state.flow
        state.flow = Next
        if flow == Break {
          break
        }
        index = index + 1
      }

      state.loops -= 1
      restore_variable(context, loop_var, saved_item)
      restore_variable(context, "tablerowloop", saved_loop)
      // Close final row and table
      if row_open {
        output = output + "</tr>\n"
      }
      output = output + "</table>"
      output
    }
    _ => ""
  }
}
