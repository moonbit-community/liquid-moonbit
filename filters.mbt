///|
/// Apply a built-in filter to evaluated values. Template rendering delegates here; arrays and numeric kinds are never serialized.
pub fn apply_filter(
  value : LiquidValue,
  name : String,
  parameters : Array[LiquidValue],
  options? : Map[String, LiquidValue] = Map([]),
) -> Result[LiquidValue, Diagnostic] {
  let result = match name {
    "plus" | "minus" | "times" | "divided_by" | "modulo" | "round" => {
      let fallback = if name == "plus" || name == "minus" {
        1.0
      } else if name == "round" {
        0.0
      } else {
        2.0
      }
      if parameters.is_empty() && value is String(_) {
        value
      } else {
        typed_numeric_filter(
          value,
          name,
          parameters.get(0).unwrap_or(Number(fallback)),
        )
      }
    }
    "date"
    | "strftime"
    | "date_to_string"
    | "date_to_xmlschema"
    | "date_to_rfc822" => date_filter(value, name, parameters)
    "slice" | "truncate" | "truncatewords" | "offset" | "limit" | "at" =>
      sequence_filter(value, name, parameters)
    "default" => {
      let empty = match value {
        Null => true
        Bool(false) => !(options.get("allow_false") is Some(Bool(true)))
        String(s) => s.is_empty()
        Array(a) => a.is_empty()
        _ => false
      }
      if empty {
        parameters.get(0).unwrap_or(String(""))
      } else {
        value
      }
    }
    "join" =>
      match value {
        Array(items) =>
          String(
            items
            .map(LiquidValue::to_string)
            .join(argument_text(parameters, 0, ", ")),
          )
        _ => value
      }
    "split" =>
      match value {
        String(s) if s.is_empty() => Array([])
        String(s) =>
          Array(
            s
            .split(argument_text(parameters, 0, " "))
            .map(fn(p) { String(p.to_owned()) })
            .collect(),
          )
        _ => value
      }
    "replace" | "remove" =>
      match value {
        String(s) => {
          let old = argument_text(
            parameters,
            0,
            if name == "replace" {
              "old"
            } else {
              "remove"
            },
          )
          let replacement = if name == "remove" {
            ""
          } else {
            argument_text(parameters, 1, "new")
          }
          String(s.replace(old~, new=replacement))
        }
        _ => value
      }
    "append" | "prepend" =>
      match value {
        String(s) => {
          let argument = argument_text(parameters, 0, name)
          String(if name == "append" { s + argument } else { argument + s })
        }
        _ => value
      }
    "concat" =>
      match (value, parameters) {
        (Array(items), []) => Array(items.copy())
        (Array(left), [Array(right), ..]) => {
          let combined = left.copy()
          for item in right {
            combined.push(item)
          }
          Array(combined)
        }
        _ =>
          return Err(
            filter_diagnostic("invalid_argument", "concat requires two arrays"),
          )
      }
    "push" | "unshift" =>
      match value {
        Array(items) => {
          let element = parameters
            .get(0)
            .unwrap_or(
              String(if name == "push" { "pushed" } else { "unshifted" }),
            )
          let result = if name == "push" { items.copy() } else { [element] }
          if name == "push" {
            result.push(element)
          } else {
            for item in items {
              result.push(item)
            }
          }
          Array(result)
        }
        _ => value
      }
    "map" =>
      match (value, parameters) {
        (Array(items), [property, ..]) =>
          Array(
            items.map(fn(item) {
              match item {
                Object(fields) =>
                  fields.get(property.to_string()).unwrap_or(Null)
                _ => item
              }
            }),
          )
        _ => value
      }
    "where" =>
      match value {
        Array(items) => {
          let selected : Array[LiquidValue] = []
          for item in items {
            let matches = match parameters {
              [property, target, ..] =>
                match item {
                  Object(fields) =>
                    match fields.get(property.to_string()) {
                      Some(v) => values_equal(v, target)
                      None => false
                    }
                  String(s) => s.contains(target.to_string())
                  _ => false
                }
              _ =>
                match item {
                  String(s) => s.contains("filter")
                  _ => false
                }
            }
            if matches {
              selected.push(item)
            }
          }
          Array(selected)
        }
        _ => value
      }
    "sort_by" =>
      match value {
        Array(items) => {
          let property = parameters.get(0)
          let sorted = items.copy()
          sorted.sort_by(fn(left, right) {
            filter_sort_key(left, property).compare(
              filter_sort_key(right, property),
            )
          })
          Array(sorted)
        }
        _ => value
      }
    "pluralize" =>
      match value {
        Number(n) | Float(n) =>
          String(
            n.to_string() +
            " " +
            argument_text(
              parameters,
              if n == 1 {
                0
              } else {
                1
              },
              if n == 1 {
                "item"
              } else {
                "items"
              },
            ),
          )
        _ => value
      }
    _ =>
      match unary_filter(value, name) {
        Some(result) => result
        None =>
          return Err(
            filter_diagnostic("unknown_filter", "Unknown filter '" + name + "'"),
          )
      }
  }
  Ok(result)
}

///|
fn argument_text(
  parameters : Array[LiquidValue],
  index : Int,
  fallback : String,
) -> String {
  parameters.get(index).map(LiquidValue::to_string).unwrap_or(fallback)
}

///|
fn filter_sort_key(value : LiquidValue, property : LiquidValue?) -> String {
  match (value, property) {
    (Object(fields), Some(key)) =>
      fields.get(key.to_string()).map(LiquidValue::to_string).unwrap_or("")
    _ => value.to_string()
  }
}
