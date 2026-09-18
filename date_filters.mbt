///|
priv struct CalendarDate {
  year : Int
  month : Int
  day : Int
  hour : Int
  minute : Int
  second : Int
  offset : String
}

///|
fn date_number(text : StringView) -> Int? {
  if text.is_empty() || !text.iter().all(fn(c) { c >= '0' && c <= '9' }) {
    return None
  }
  Some(@string.parse_int(text)) catch {
    _ => None
  }
}

///|
fn month_lengths(year : Int) -> Array[Int] {
  [
    31,
    if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
      29
    } else {
      28
    },
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
}

///|
fn parse_calendar_date(text : String) -> CalendarDate? {
  if text.length() < 10 || text[4] != 45 || text[7] != 45 {
    return None
  }
  // Check ASCII before slicing to keep malformed Unicode input safe.
  for c in text.iter() {
    if c.to_int() > 127 {
      return None
    }
  }
  guard date_number(text[:4]) is Some(year) && year > 0 else { return None }
  guard date_number(text[5:7]) is Some(month) && month >= 1 && month <= 12 else {
    return None
  }
  guard date_number(text[8:10]) is Some(day) &&
    day >= 1 &&
    day <= month_lengths(year)[month - 1] else {
    return None
  }
  let mut hour = 0
  let mut minute = 0
  let mut second = 0
  let mut offset = "+0000"
  if text.length() > 10 {
    if text.length() < 19 ||
      (text[10] != 84 && text[10] != 32) ||
      text[13] != 58 ||
      text[16] != 58 {
      return None
    }
    guard date_number(text[11:13]) is Some(h) && h < 24 else { return None }
    guard date_number(text[14:16]) is Some(m) && m < 60 else { return None }
    guard date_number(text[17:19]) is Some(s) && s < 60 else { return None }
    hour = h
    minute = m
    second = s
    let zone = text[19:].to_owned()
    if zone != "" && zone != "Z" {
      if zone.length() != 6 || (zone[0] != 43 && zone[0] != 45) || zone[3] != 58 {
        return None
      }
      guard date_number(zone[1:3]) is Some(h) && h < 24 else { return None }
      guard date_number(zone[4:6]) is Some(m) && m < 60 else { return None }
      offset = zone[:3].to_owned() + zone[4:].to_owned()
    }
  }
  Some({ year, month, day, hour, minute, second, offset, })
}

///|
fn pad_number(n : Int, width : Int) -> String {
  let text = n.to_string()
  "0".repeat((width - text.length()).max(0)) + text
}

///|
fn CalendarDate::format(self : CalendarDate, format : String) -> String? {
  let months = [
    "January", "February", "March", "April", "May", "June", "July", "August", "September",
    "October", "November", "December",
  ]
  let weekdays = [
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
  ]
  let lengths = month_lengths(self.year)
  let mut ordinal = self.day
  for i in 0..<(self.month - 1) {
    ordinal += lengths[i]
  }
  let y = self.year - 1
  let weekday = (365 * y + y / 4 - y / 100 + y / 400 + ordinal) % 7
  let mut output = ""
  let mut directive = false
  for c in format.iter() {
    if !directive {
      if c == '%' {
        directive = true
      } else {
        output += c.to_string()
      }
      continue
    }
    directive = false
    output += match c {
      '%' => "%"
      'Y' => pad_number(self.year, 4)
      'y' => pad_number(self.year % 100, 2)
      'm' => pad_number(self.month, 2)
      'd' => pad_number(self.day, 2)
      'e' => (if self.day < 10 { " " } else { "" }) + self.day.to_string()
      'B' => months[self.month - 1]
      'b' | 'h' => months[self.month - 1][:3].to_owned()
      'A' => weekdays[weekday]
      'a' => weekdays[weekday][:3].to_owned()
      'j' => pad_number(ordinal, 3)
      'w' => weekday.to_string()
      'u' => (if weekday == 0 { 7 } else { weekday }).to_string()
      'H' => pad_number(self.hour, 2)
      'I' =>
        pad_number(if self.hour % 12 == 0 { 12 } else { self.hour % 12 }, 2)
      'M' => pad_number(self.minute, 2)
      'S' => pad_number(self.second, 2)
      'p' => if self.hour < 12 { "AM" } else { "PM" }
      'z' => self.offset
      'Z' => if self.offset == "+0000" { "UTC" } else { self.offset }
      'F' => self.format("%Y-%m-%d").unwrap_or("")
      'T' => self.format("%H:%M:%S").unwrap_or("")
      'R' => self.format("%H:%M").unwrap_or("")
      'D' => self.format("%m/%d/%y").unwrap_or("")
      'n' => "\n"
      't' => "\t"
      _ => return None
    }
  }
  if directive {
    None
  } else {
    Some(output)
  }
}

///|
fn date_filter(
  value : LiquidValue,
  name : String,
  parameters : Array[String],
) -> LiquidValue {
  guard value is String(text) && parse_calendar_date(text) is Some(date) else {
    return value
  }
  let format = match name {
    "date_to_string" => "%d %b %Y"
    "date_to_rfc822" => "%a, %d %b %Y %H:%M:%S %z"
    "date_to_xmlschema" => "%Y-%m-%dT%H:%M:%S"
    _ =>
      if parameters.is_empty() {
        "%Y-%m-%d"
      } else {
        unquote_argument(parameters[0])
      }
  }
  guard date.format(format) is Some(formatted) else { return value }
  if name == "date_to_xmlschema" {
    let zone = if date.offset == "+0000" {
      "Z"
    } else {
      date.offset[:3].to_owned() + ":" + date.offset[3:].to_owned()
    }
    String(formatted + zone)
  } else {
    String(formatted)
  }
}
