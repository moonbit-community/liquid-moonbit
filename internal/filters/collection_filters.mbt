///|
fn collection_filter(value : LiquidValue, name : String) -> LiquidValue? {
  let result = match name {
    "first" =>
      match value {
        Array(arr) =>
          if arr.length() > 0 {
            arr[0]
          } else {
            @value.null_value()
          }
        String(s) =>
          if s.length() > 0 {
            @value.string_value(s[0:1].to_owned())
          } else {
            @value.null_value()
          }
        _ => @value.null_value()
      }
    "last" =>
      match value {
        Array(arr) =>
          if arr.length() > 0 {
            arr[arr.length() - 1]
          } else {
            @value.null_value()
          }
        String(s) =>
          if s.length() > 0 {
            @value.string_value(s[s.length() - 1:].to_owned())
          } else {
            @value.null_value()
          }
        _ => @value.null_value()
      }
    "reverse" =>
      match value {
        Array(arr) => {
          let reversed : Array[LiquidValue] = []
          let mut i = arr.length() - 1
          while i >= 0 {
            reversed.push(arr[i])
            i = i - 1
          }
          @value.array_value(reversed)
        }
        String(s) => {
          let chars = s.to_string()
          let mut reversed = ""
          let mut i = chars.length() - 1
          while i >= 0 {
            reversed = reversed + chars[i:i + 1].to_owned()
            i = i - 1
          }
          @value.string_value(reversed)
        }
        _ => value
      }
    "sort" =>
      match value {
        Array(arr) => {
          let sorted = Array::from_iter(arr.iter())
          // Selection sort - simpler and more reliable
          let mut i = 0
          while i < sorted.length() {
            let mut min_idx = i
            let mut j = i + 1
            while j < sorted.length() {
              if sorted[j].to_string() < sorted[min_idx].to_string() {
                min_idx = j
              }
              j = j + 1
            }
            if min_idx != i {
              let temp = sorted[i]
              sorted[i] = sorted[min_idx]
              sorted[min_idx] = temp
            }
            i = i + 1
          }
          @value.array_value(sorted)
        }
        _ => value
      }
    "pop" =>
      match value {
        Array(arr) =>
          // Basic pop - remove last element
          if arr.length() > 0 {
            let new_arr : Array[LiquidValue] = []
            for i in 0..<(arr.length() - 1) {
              new_arr.push(arr[i])
            }
            @value.array_value(new_arr)
          } else {
            @value.array_value(arr)
          }
        _ => value
      }
    "shift" =>
      match value {
        Array(arr) =>
          // Basic shift - remove first element
          if arr.length() > 0 {
            let new_arr : Array[LiquidValue] = []
            for i in 1..<arr.length() {
              new_arr.push(arr[i])
            }
            @value.array_value(new_arr)
          } else {
            @value.array_value(arr)
          }
        _ => value
      }
    "select" =>
      match value {
        Array(arr) => {
          // For now, select returns non-empty/truthy elements
          let selected : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) => if s != "" { selected.push(item) }
              Number(n) | Float(n) => if n != 0.0 { selected.push(item) }
              Bool(b) => if b { selected.push(item) }
              Array(a) => if a.length() > 0 { selected.push(item) }
              Object(_) => selected.push(item)
              Null => ()
            }
          }
          @value.array_value(selected)
        }
        _ => value
      }
    "reject" =>
      match value {
        Array(arr) => {
          // Reject is opposite of select - returns empty/falsy elements
          let rejected : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) => if s == "" { rejected.push(item) }
              Number(n) | Float(n) => if n == 0.0 { rejected.push(item) }
              Bool(b) => if !b { rejected.push(item) }
              Array(a) => if a.length() == 0 { rejected.push(item) }
              Null => rejected.push(item)
              _ => ()
            }
          }
          @value.array_value(rejected)
        }
        _ => value
      }
    "compact" =>
      match value {
        Array(arr) => {
          // Remove null/empty values
          let compacted : Array[LiquidValue] = []
          for item in arr {
            match item {
              Null => ()
              String(s) => if s != "" { compacted.push(item) }
              _ => compacted.push(item)
            }
          }
          @value.array_value(compacted)
        }
        _ => value
      }
    "uniq" =>
      match value {
        Array(arr) => {
          // Remove duplicates (simple string-based comparison)
          let unique : Array[LiquidValue] = []
          for item in arr {
            let item_str = item.to_string()
            let mut found = false
            for existing in unique {
              if existing.to_string() == item_str {
                found = true
                break
              }
            }
            if !found {
              unique.push(item)
            }
          }
          @value.array_value(unique)
        }
        _ => value
      }
    "flatten" =>
      match value {
        Array(arr) => {
          // Flatten nested arrays one level
          let flattened : Array[LiquidValue] = []
          for item in arr {
            match item {
              Array(nested) =>
                for nested_item in nested {
                  flattened.push(nested_item)
                }
              _ => flattened.push(item)
            }
          }
          @value.array_value(flattened)
        }
        _ => value
      }
    "group_by" =>
      match value {
        Array(arr) => {
          // Basic group_by - group by string length
          let short_items : Array[LiquidValue] = []
          let long_items : Array[LiquidValue] = []
          for item in arr {
            match item {
              String(s) =>
                if s.length() <= 5 {
                  short_items.push(item)
                } else {
                  long_items.push(item)
                }
              _ => short_items.push(item)
            }
          }
          // Return array of groups
          @value.array_value([
            @value.array_value(short_items),
            @value.array_value(long_items),
          ])
        }
        _ => value
      }
    _ => return None
  }
  Some(result)
}
