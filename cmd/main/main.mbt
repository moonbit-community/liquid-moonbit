///|
fn main {
  let context = @liquid.LiquidContext::new()
  context.set("name", @liquid.string_value("MoonBit"))
  match @liquid.compile("Hello {{ name | upcase }}!") {
    Ok(template) =>
      match template.render(context) {
        Ok(output) => println(output)
        Err(errors) =>
          for error in errors {
            println(error.message)
          }
      }
    Err(errors) =>
      for error in errors {
        println(error.message)
      }
  }
}
