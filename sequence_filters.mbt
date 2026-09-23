///|
fn integer_argument(
  parameters : Array[String],
  index : Int,
  fallback : Int,
) -> Int {
  match parameters.get(index) {
    Some(text) => parse_integer(text).unwrap_or(fallback)
    None => fallback
  }
}

///|
fn slice_bounds(size : Int, start : Int, count : Int) -> (Int, Int) {
  let start = if start < 0 { size + start } else { start }
  if start < 0 || start >= size || count <= 0 {
    return (0, 0)
  }
  (start, start + count.min(size - start))
}

///|
fn sequence_filter(
  value : LiquidValue,
  name : String,
  parameters : Array[String],
) -> LiquidValue {
  match name {
    "truncate" =>
      match value {
        String(s) => {
          let chars = s.iter().collect()
          let size = integer_argument(parameters, 0, 50).max(0)
          let suffix = parameters.get(1).map(unquote_argument).unwrap_or("...")
          if chars.length() <= size {
            return value
          }
          let keep = (size - suffix.iter().count()).max(0)
          String(String::from_array(chars[:keep]) + suffix)
        }
        _ => value
      }
    "truncatewords" =>
      match value {
        String(s) => {
          let words = s
            .split(" ")
            .flat_map(fn(w) { w.split("\n") })
            .flat_map(fn(w) { w.split("\t") })
            .flat_map(fn(w) { w.split("\r") })
            .filter(fn(w) { !w.is_empty() })
            .map(fn(w) { w.to_owned() })
            .collect()
          let count = integer_argument(parameters, 0, 15).max(1)
          let suffix = parameters.get(1).map(unquote_argument).unwrap_or("...")
          if words.length() <= count {
            value
          } else {
            String(words[:count].to_owned().join(" ") + suffix)
          }
        }
        _ => value
      }
    "slice" => {
      let start = integer_argument(parameters, 0, 0)
      // Retain the public no-argument convenience; explicit starts default to one element.
      let count = integer_argument(
        parameters,
        1,
        if parameters.is_empty() {
          3
        } else {
          1
        },
      )
      match value {
        Array(items) => {
          let (from, to) = slice_bounds(items.length(), start, count)
          Array(items[from:to].to_owned())
        }
        String(s) => {
          let chars = s.iter().collect()
          let (from, to) = slice_bounds(chars.length(), start, count)
          String(String::from_array(chars[from:to]))
        }
        _ => value
      }
    }
    "offset" | "limit" =>
      match value {
        Array(items) => {
          let count = integer_argument(
              parameters,
              0,
              if name == "offset" {
                1
              } else {
                2
              },
            )
            .max(0)
            .min(items.length())
          if name == "offset" {
            Array(items[count:].to_owned())
          } else {
            Array(items[:count].to_owned())
          }
        }
        _ => value
      }
    "at" =>
      match value {
        Array(items) => {
          let index = integer_argument(parameters, 0, 0)
          items
          .get(if index < 0 { items.length() + index } else { index })
          .unwrap_or(Null)
        }
        _ => value
      }
    _ => value
  }
}
