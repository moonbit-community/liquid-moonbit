///|
fn scalar_filter(value : LiquidValue, name : String) -> LiquidValue? {
  let result = match name {
    "size" | "length" =>
      match value {
        String(s) => Number(s.length().to_double())
        Array(arr) => Number(arr.length().to_double())
        Object(obj) => Number(obj.length().to_double())
        _ => Number(0.0)
      }
    "ceil" =>
      match value {
        Number(n) | Float(n) => Number(n.ceil())
        String(_) => value
        _ => value
      }
    "floor" =>
      match value {
        Number(n) | Float(n) => Number(n.floor())
        String(_) => value
        _ => value
      }
    "abs" =>
      match value {
        Number(n) | Float(n) =>
          numeric_result(n.abs(), value is Float(_) || n != n.trunc())
        String(_) => value
        _ => value
      }
    "asset_url" =>
      match value {
        String(s) => String("/assets/" + s)
        _ => value
      }
    "absolute_url" =>
      match value {
        String(s) => String("https://example.com" + s)
        _ => value
      }
    "relative_url" =>
      match value {
        String(s) =>
          if s[0:1].to_owned() == "/" {
            value
          } else {
            String("/" + s)
          }
        _ => value
      }
    "money" =>
      match value {
        Number(n) | Float(n) => String("$" + n.to_string())
        String(s) => String("$" + s)
        _ => value
      }
    "money_with_currency" =>
      match value {
        Number(n) | Float(n) => String("$" + n.to_string() + " USD")
        String(s) => String("$" + s + " USD")
        _ => value
      }
    "money_without_currency" =>
      match value {
        Number(n) | Float(n) => String(n.to_string())
        String(s) => String(s.replace(old="$", new=""))
        _ => value
      }
    "money_without_trailing_zeros" =>
      match value {
        Number(n) | Float(n) => {
          let str_val = n.to_string()
          if str_val.strip_suffix(".0") != None {
            String("$" + str_val[0:str_val.length() - 2].to_owned())
          } else {
            String("$" + str_val)
          }
        }
        String(s) => String("$" + s)
        _ => value
      }
    "reading_time" =>
      match value {
        String(text) => {
          // Estimate reading time based on word count (average 200 words per minute)
          let word_count = text.split(" ").collect().length()
          let minutes = (word_count.to_double() / 200.0).ceil()
          Number(minutes)
        }
        _ => Number(1.0) // Default to 1 minute
      }
    _ => return None
  }
  Some(result)
}
