///|
fn string_filter(value : LiquidValue, name : String) -> LiquidValue? {
  let result = match name {
    "upcase" =>
      match value {
        String(s) => String(s.to_upper())
        _ => value
      }
    "downcase" =>
      match value {
        String(s) => String(s.to_lower())
        _ => value
      }
    "trim" | "strip" =>
      match value {
        String(s) => String(s.trim(chars=" \t\n\r").to_owned())
        _ => value
      }
    "escape" =>
      match value {
        String(s) => {
          let escaped = s
            .to_string()
            .replace(old="&", new="&amp;")
            .replace(old="<", new="&lt;")
            .replace(old=">", new="&gt;")
            .replace(old="\"", new="&quot;")
            .replace(old="'", new="&#39;")
          String(escaped)
        }
        _ => value
      }
    "lstrip" =>
      match value {
        String(s) => String(s.trim_start(chars=" \t\n\r").to_owned())
        _ => value
      }
    "rstrip" =>
      match value {
        String(s) => String(s.trim_end(chars=" \t\n\r").to_owned())
        _ => value
      }
    "strip_tags" =>
      match value {
        String(s) => {
          // Enhanced HTML tag removal
          let mut result = s.to_string()
          result = result.replace(old="<script>", new="")
          result = result.replace(old="</script>", new="")
          result = result.replace(old="<style>", new="")
          result = result.replace(old="</style>", new="")
          result = result.replace(old="<div>", new="")
          result = result.replace(old="</div>", new="")
          result = result.replace(old="<p>", new="")
          result = result.replace(old="</p>", new="")
          result = result.replace(old="<a>", new="")
          result = result.replace(old="</a>", new="")
          result = result.replace(old="<span>", new="")
          result = result.replace(old="</span>", new="")
          String(result)
        }
        _ => value
      }
    "normalize_whitespace" =>
      match value {
        String(s) => {
          // Normalize whitespace (replace multiple spaces with single space)
          let mut result = s.to_string()
          result = result.replace(old="\t", new=" ") // Replace tabs
          result = result.replace(old="\n", new=" ") // Replace newlines
          result = result.replace(old="\r", new=" ") // Replace carriage returns

          // Replace multiple consecutive spaces with single space (iteratively)
          let mut prev_length = result.length()
          result = result.replace(old="  ", new=" ") // Replace double spaces
          while result.length() != prev_length {
            prev_length = result.length()
            result = result.replace(old="  ", new=" ")
          }
          String(result.trim(chars=" ").to_owned())
        }
        _ => value
      }
    "capitalize" =>
      match value {
        String(s) =>
          if s.length() > 0 {
            let first_char_end = match s.offset_of_nth_char(1) {
              Some(offset) => offset
              None => s.length()
            }
            let first_char = s[0:first_char_end].to_owned().to_upper()
            let rest = if first_char_end < s.length() {
              s[first_char_end:].to_owned().to_lower()
            } else {
              ""
            }
            String(first_char.to_string() + rest.to_string())
          } else {
            value
          }
        _ => value
      }
    "newline_to_br" =>
      match value {
        String(s) => String(s.replace(old="\n", new="<br>"))
        _ => value
      }
    "strip_html" =>
      match value {
        String(s) => {
          // Simple HTML tag removal (basic implementation)
          let mut result = s.to_string()
          result = result.replace(old="<script>", new="")
          result = result.replace(old="</script>", new="")
          result = result.replace(old="<div>", new="")
          result = result.replace(old="</div>", new="")
          result = result.replace(old="<p>", new="")
          result = result.replace(old="</p>", new="")
          String(result)
        }
        _ => value
      }
    "strip_newlines" =>
      match value {
        String(s) =>
          String(s.replace(old="\n", new="").replace(old="\r", new=""))
        _ => value
      }
    "url_encode" =>
      match value {
        String(s) => {
          // Basic URL encoding for common characters
          let mut encoded = s.to_string()
          encoded = encoded.replace(old=" ", new="%20")
          encoded = encoded.replace(old="&", new="%26")
          encoded = encoded.replace(old="=", new="%3D")
          encoded = encoded.replace(old="?", new="%3F")
          encoded = encoded.replace(old="#", new="%23")
          encoded = encoded.replace(old="+", new="%2B")
          String(encoded)
        }
        _ => value
      }
    "url_decode" =>
      match value {
        String(s) => {
          // Basic URL decoding for common characters
          let mut decoded = s.to_string()
          decoded = decoded.replace(old="%20", new=" ")
          decoded = decoded.replace(old="%26", new="&")
          decoded = decoded.replace(old="%3D", new="=")
          decoded = decoded.replace(old="%3F", new="?")
          decoded = decoded.replace(old="%23", new="#")
          decoded = decoded.replace(old="%2B", new="+")
          String(decoded)
        }
        _ => value
      }
    _ => return None
  }
  Some(result)
}
