///|
/// Find a delimiter outside single- and double-quoted Liquid strings.
fn find_unquoted(text : String, delimiter : String) -> Int? {
  let mut quote : UInt16 = 0
  for i in 0..<text.length() {
    let c = text[i]
    if quote != 0 {
      if c == quote {
        quote = 0
      }
    } else if c == 39 || c == 34 {
      quote = c
    } else if i + delimiter.length() <= text.length() {
      let mut matches = true
      for j in 0..<delimiter.length() {
        if text[i + j] != delimiter[j] {
          matches = false
          break
        }
      }
      if matches {
        return Some(i)
      }
    }
  }
  None
}

///|
fn split_unquoted(text : String, delimiter : String) -> Array[String] {
  let parts : Array[String] = []
  let mut rest = text
  while find_unquoted(rest, delimiter) is Some(index) {
    parts.push(rest[:index].to_owned())
    rest = rest[index + delimiter.length():].to_owned()
  }
  parts.push(rest)
  parts
}

///|
fn parse_output(expression : String) -> (String, Array[Filter]) {
  let parts = split_unquoted(expression, "|")
  let filters : Array[Filter] = []
  for part in parts[1:] {
    match find_unquoted(part, ":") {
      Some(index) =>
        filters.push(
          filter(
            part[:index].trim().to_owned(),
            split_unquoted(part[index + 1:].to_owned(), ",").map(fn(p) {
              p.trim().to_owned()
            }),
          ),
        )
      None => filters.push(filter(part.trim().to_owned(), []))
    }
  }
  (parts[0].trim().to_owned(), filters)
}
