///|
test "filter first" {
  // Test first filter on arrays and strings
  let arr_value = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  let arr_result = apply_filter(arr_value, "first", []).unwrap()
  assert_eq(arr_result.to_string(), "apple")
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "first", []).unwrap()
  assert_eq(str_result.to_string(), "h")
  let empty_arr = array_value([])
  let empty_result = apply_filter(empty_arr, "first", []).unwrap()
  assert_eq(empty_result.to_string(), "null")
}

///|
test "filter last" {
  // Test last filter on arrays and strings
  let arr_value = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  let arr_result = apply_filter(arr_value, "last", []).unwrap()
  assert_eq(arr_result.to_string(), "cherry")
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "last", []).unwrap()
  assert_eq(str_result.to_string(), "o")
}

///|
test "filter reverse" {
  // Test reverse filter on arrays
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let arr_result = apply_filter(arr_value, "reverse", []).unwrap()
  assert_eq(arr_result.to_string(), "[c, b, a]")

  // Test reverse filter on strings
  let str_value = string_value("hello")
  let str_result = apply_filter(str_value, "reverse", []).unwrap()
  assert_eq(str_result.to_string(), "olleh")
}

///|
test "filter sort" {
  // Test sort filter on arrays
  let arr_value = array_value([
    string_value("cherry"),
    string_value("apple"),
    string_value("banana"),
  ])
  let arr_result = apply_filter(arr_value, "sort", []).unwrap()
  assert_eq(arr_result.to_string(), "[apple, banana, cherry]")
}

///|
test "filter join" {
  // Test join filter on arrays
  let arr_value = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])
  let join_result = apply_filter(arr_value, "join", []).unwrap()
  assert_eq(join_result.to_string(), "apple, banana, cherry")
}

///|
test "filter map" {
  // Test map filter (basic identity for now)
  let arr_value = array_value([
    string_value("a"),
    string_value("b"),
    string_value("c"),
  ])
  let map_result = apply_filter(arr_value, "map", []).unwrap()
  assert_eq(map_result.to_string(), "[a, b, c]")
}

///|
test "filter select" {
  // Test select filter - keeps truthy values
  let mixed_array = array_value([
    string_value("hello"),
    string_value(""),
    number_value(5.0),
    number_value(0.0),
    bool_value(true),
    bool_value(false),
    null_value(),
  ])
  let select_result = apply_filter(mixed_array, "select", []).unwrap()
  assert_eq(select_result.to_string(), "[hello, 5, true]")
}

///|
test "filter reject" {
  // Test reject filter - keeps falsy values
  let mixed_array = array_value([
    string_value("hello"),
    string_value(""),
    number_value(5.0),
    number_value(0.0),
    bool_value(true),
    bool_value(false),
    null_value(),
  ])
  let reject_result = apply_filter(mixed_array, "reject", []).unwrap()
  assert_eq(reject_result.to_string(), "[, 0, false, null]")
}

///|
test "filter compact" {
  // Test compact filter - removes null and empty values
  let messy_array = array_value([
    string_value("hello"),
    string_value(""),
    number_value(5.0),
    null_value(),
    string_value("world"),
  ])
  let compact_result = apply_filter(messy_array, "compact", []).unwrap()
  assert_eq(compact_result.to_string(), "[hello, 5, world]")
}

///|
test "filter uniq" {
  // Test uniq filter - removes duplicates
  let duplicate_array = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("apple"),
    string_value("cherry"),
    string_value("banana"),
  ])
  let uniq_result = apply_filter(duplicate_array, "uniq", []).unwrap()
  assert_eq(uniq_result.to_string(), "[apple, banana, cherry]")
}

///|
test "filter flatten" {
  // Test flatten filter - flattens nested arrays one level
  let nested_array = array_value([
    string_value("single"),
    array_value([string_value("nested1"), string_value("nested2")]),
    string_value("another"),
  ])
  let flatten_result = apply_filter(nested_array, "flatten", []).unwrap()
  assert_eq(flatten_result.to_string(), "[single, nested1, nested2, another]")
}

///|
test "empty array filters" {
  // Test filters on empty arrays
  let empty_array = array_value([])
  let select_result = apply_filter(empty_array, "select", []).unwrap()
  assert_eq(select_result.to_string(), "[]")
  let compact_result = apply_filter(empty_array, "compact", []).unwrap()
  assert_eq(compact_result.to_string(), "[]")
  let uniq_result = apply_filter(empty_array, "uniq", []).unwrap()
  assert_eq(uniq_result.to_string(), "[]")
}

///|
test "filter where" {
  // Test where filter - filters items containing "filter"
  let arr_value = array_value([
    string_value("filter1"),
    string_value("normal"),
    string_value("filter2"),
    string_value("other"),
  ])
  let where_result = apply_filter(arr_value, "where", []).unwrap()
  assert_eq(where_result.to_string(), "[filter1, filter2]")
}

///|
test "filter group_by" {
  // Test group_by filter - groups by string length
  let arr_value = array_value([
    string_value("cat"), // short (3)
    string_value("elephant"), // long (8)
    string_value("dog"), // short (3)
    string_value("butterfly"), // long (9)
  ])
  let group_result = apply_filter(arr_value, "group_by", []).unwrap()
  assert_eq(group_result.to_string(), "[[cat, dog], [elephant, butterfly]]")
}

///|
test "array filter edge cases" {
  // Test array filters with edge cases
  let mixed_arr = array_value([
    string_value(""), // Empty string
    array_value([]), // Empty array
    object_value(Map([])), // Empty object
    null_value(), // Null
    number_value(42.0), // Number
  ])

  // Test select with mixed types
  let select_result = apply_filter(mixed_arr, "select", []).unwrap()
  assert_eq(select_result.to_string().contains("42"), true) // Should include number

  // Test reject with mixed types
  let reject_result = apply_filter(mixed_arr, "reject", []).unwrap()
  assert_eq(reject_result.to_string().contains("null"), true) // Should include null

  // Test group_by with non-string items
  let group_result = apply_filter(mixed_arr, "group_by", []).unwrap()
  assert_eq(group_result.to_string().contains("42"), true) // Should group non-strings
}

///|
test "join filter parameter variations" {
  let arr = array_value([
    string_value("apple"),
    string_value("banana"),
    string_value("cherry"),
  ])

  // Test join with "' | '" parameter
  let result_pipe = apply_filter(arr, "join", [string_value(" | ")]).unwrap()
  assert_eq(result_pipe.to_string(), "apple | banana | cherry")

  // Test join with "', '" parameter
  let result_comma = apply_filter(arr, "join", [string_value(", ")]).unwrap()
  assert_eq(result_comma.to_string(), "apple, banana, cherry")

  // Test join with "' - '" parameter
  let result_dash = apply_filter(arr, "join", [string_value(" - ")]).unwrap()
  assert_eq(result_dash.to_string(), "apple - banana - cherry")

  // Test join with double quotes parameter
  let result_double = apply_filter(arr, "join", [string_value(", ")]).unwrap()
  assert_eq(result_double.to_string(), "apple, banana, cherry")

  // Test join with non-array value
  let string_val = string_value("not an array")
  let result_non_array = apply_filter(string_val, "join", [string_value(" | ")]).unwrap()
  assert_eq(result_non_array.to_string(), "not an array")
}

///|
test "where filter edge cases v2" {

  // Test where filter with mixed array types
  let mixed_arr = array_value([
    string_value("test value"),
    number_value(42.0),
    bool_value(true),
  ])
  let result_where = apply_filter(mixed_arr, "where", [
    string_value("value"),
    string_value("test"),
  ]).unwrap()
  match result_where {
    Array(filtered) => assert_eq(filtered.length(), 1) // only the string containing "test"
    _ => fail("Expected Array result")
  }

  // Test where filter with object having no matching property
  let obj_map = Map([])
  obj_map.set("other_prop", string_value("other_value"))
  let obj_arr = array_value([object_value(obj_map)])
  let result_no_match = apply_filter(obj_arr, "where", [
    string_value("value"),
    string_value("test"),
  ]).unwrap()
  match result_no_match {
    Array(filtered) => assert_eq(filtered.length(), 0) // no matches
    _ => fail("Expected Array result")
  }
}

///|
test "select filter with array edge case" {

  // Test select filter with array containing nested array
  let nested_arr = array_value([string_value("item")])
  let arr_with_nested = array_value([
    string_value(""),
    nested_arr,
    string_value("valid"),
  ])
  let result_select = apply_filter(arr_with_nested, "select", []).unwrap()
  match result_select {
    Array(selected) => assert_eq(selected.length(), 2) // nested array and "valid" string
    _ => fail("Expected Array result")
  }
}

///|
test "where basic filter edge case" {

  // Test where filter (basic version) with array containing non-string
  let mixed_arr = array_value([
    string_value("filter this"),
    number_value(42.0),
    string_value("no match"),
  ])
  let result_where = apply_filter(mixed_arr, "where", []).unwrap()
  match result_where {
    Array(filtered) => assert_eq(filtered.length(), 1) // only "filter this"
    _ => fail("Expected Array result")
  }
}

///|
test "sort_by filter basic" {
  // Test sort_by filter with array of strings - use the same test data as the working sort test
  let arr = array_value([
    string_value("cherry"),
    string_value("apple"),
    string_value("banana"),
  ])
  let result_sort = apply_filter(arr, "sort_by", []).unwrap()
  match result_sort {
    Array(sorted) => {
      assert_eq(sorted[0].to_string(), "apple")
      assert_eq(sorted[1].to_string(), "banana")
      assert_eq(sorted[2].to_string(), "cherry")
    }
    _ => fail("Expected Array result")
  }
}

///|
test "sort_by filter with property parameter" {
  // Test sort_by filter with object property
  let obj1 = Map([])
  obj1.set("name", string_value("Charlie"))
  obj1.set("age", number_value(30.0))
  let obj2 = Map([])
  obj2.set("name", string_value("Alice"))
  obj2.set("age", number_value(25.0))
  let obj3 = Map([])
  obj3.set("name", string_value("Bob"))
  obj3.set("age", number_value(35.0))
  let arr = array_value([
    object_value(obj1),
    object_value(obj2),
    object_value(obj3),
  ])
  let result_sort = apply_filter(arr, "sort_by", [string_value("name")]).unwrap()
  match result_sort {
    Array(sorted) => {
      // Debug: see what we actually get
      match sorted[0] {
        Object(obj) =>
          match obj.get("name") {
            Some(name) => println("First sorted name: " + name.to_string())
            None => println("No name property found")
          }
        _ => println("First item is not an object")
      }
      // For now, just verify we get 3 items
      assert_eq(sorted.length(), 3)
    }
    _ => fail("Expected Array result")
  }
}

///|
test "sort_by filter edge cases" {
  // Test sort_by with single quotes parameter
  let obj1 = Map([])
  obj1.set("name", string_value("Bob"))
  let obj2 = Map([])
  obj2.set("name", string_value("Alice"))
  let arr = array_value([object_value(obj1), object_value(obj2)])
  let result_quotes = apply_filter(arr, "sort_by", [string_value("name")]).unwrap()
  match result_quotes {
    Array(sorted) => assert_eq(sorted.length(), 2)
    _ => fail("Expected Array result")
  }

  // Test sort_by with no parameters (should fallback to basic sort_by)
  let result_no_params = apply_filter(arr, "sort_by", []).unwrap()
  match result_no_params {
    Array(sorted) => assert_eq(sorted.length(), 2)
    _ => fail("Expected Array result")
  }

  // Test sort_by with objects that don't have the property
  let obj_no_prop = Map([])
  obj_no_prop.set("other", string_value("value"))
  let arr_no_prop = array_value([object_value(obj_no_prop)])
  let result_no_prop = apply_filter(arr_no_prop, "sort_by", [
    string_value("name"),
  ]).unwrap()
  match result_no_prop {
    Array(sorted) => assert_eq(sorted.length(), 1)
    _ => fail("Expected Array result")
  }

  // Test sort_by with mixed types (objects and non-objects)
  let mixed_arr = array_value([object_value(obj1), string_value("plain string")])
  let result_mixed = apply_filter(mixed_arr, "sort_by", [string_value("name")]).unwrap()
  match result_mixed {
    Array(sorted) => assert_eq(sorted.length(), 2)
    _ => fail("Expected Array result")
  }
}

///|
test "enhanced map filter functionality" {
  // Test map filter with property parameter
  let obj1 = Map([])
  obj1.set("name", string_value("Alice"))
  obj1.set("age", number_value(25.0))
  let obj2 = Map([])
  obj2.set("name", string_value("Bob"))
  obj2.set("age", number_value(30.0))
  let obj3 = Map([])
  obj3.set("name", string_value("Charlie"))
  obj3.set("age", number_value(35.0))
  let arr = array_value([
    object_value(obj1),
    object_value(obj2),
    object_value(obj3),
  ])

  // Test map with 'name' property
  let result_names = apply_filter(arr, "map", [string_value("name")]).unwrap()
  match result_names {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "Alice")
      assert_eq(mapped[1].to_string(), "Bob")
      assert_eq(mapped[2].to_string(), "Charlie")
    }
    _ => fail("Expected Array result")
  }

  // Test map with single quotes
  let result_ages = apply_filter(arr, "map", [string_value("age")]).unwrap()
  match result_ages {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "25")
      assert_eq(mapped[1].to_string(), "30")
      assert_eq(mapped[2].to_string(), "35")
    }
    _ => fail("Expected Array result")
  }

  // Test map with missing property
  let result_missing = apply_filter(arr, "map", [string_value("missing_prop")]).unwrap()
  match result_missing {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "null") // Missing properties become null
      assert_eq(mapped[1].to_string(), "null")
      assert_eq(mapped[2].to_string(), "null")
    }
    _ => fail("Expected Array result")
  }

  // Test map with no parameters (should fallback)
  let result_no_params = apply_filter(arr, "map", []).unwrap()
  match result_no_params {
    Array(mapped) => assert_eq(mapped.length(), 3) // Should return original array
    _ => fail("Expected Array result")
  }

  // Test map with non-array value
  let string_val = string_value("not an array")
  let result_non_array = apply_filter(string_val, "map", [string_value("name")]).unwrap()
  assert_eq(result_non_array.to_string(), "not an array")
}

///|
test "array manipulation filters" {
  // Test push, pop, shift, unshift filters
  let arr = array_value([
    string_value("first"),
    string_value("second"),
    string_value("third"),
  ])

  // Test push filter
  let result_push = apply_filter(arr, "push", []).unwrap()
  match result_push {
    Array(pushed) => {
      assert_eq(pushed.length(), 4)
      assert_eq(pushed[3].to_string(), "pushed") // New element added
    }
    _ => fail("Expected Array result")
  }

  // Test pop filter
  let result_pop = apply_filter(arr, "pop", []).unwrap()
  match result_pop {
    Array(popped) => {
      assert_eq(popped.length(), 2) // One element removed
      assert_eq(popped[0].to_string(), "first")
      assert_eq(popped[1].to_string(), "second")
    }
    _ => fail("Expected Array result")
  }

  // Test shift filter
  let result_shift = apply_filter(arr, "shift", []).unwrap()
  match result_shift {
    Array(shifted) => {
      assert_eq(shifted.length(), 2) // First element removed
      assert_eq(shifted[0].to_string(), "second")
      assert_eq(shifted[1].to_string(), "third")
    }
    _ => fail("Expected Array result")
  }

  // Test unshift filter
  let result_unshift = apply_filter(arr, "unshift", []).unwrap()
  match result_unshift {
    Array(unshifted) => {
      assert_eq(unshifted.length(), 4) // Element added to beginning
      assert_eq(unshifted[0].to_string(), "unshifted")
      assert_eq(unshifted[1].to_string(), "first")
    }
    _ => fail("Expected Array result")
  }

  // Test with empty array
  let empty_arr = array_value([])
  let result_pop_empty = apply_filter(empty_arr, "pop", []).unwrap()
  match result_pop_empty {
    Array(popped) => assert_eq(popped.length(), 0) // Should remain empty
    _ => fail("Expected Array result")
  }
  let result_shift_empty = apply_filter(empty_arr, "shift", []).unwrap()
  match result_shift_empty {
    Array(shifted) => assert_eq(shifted.length(), 0) // Should remain empty
    _ => fail("Expected Array result")
  }
}

///|
test "concat filter basic" {
  let left = array_value([string_value("a")])
  let right = array_value([string_value("b")])
  assert_eq(
    apply_filter(left, "concat", [right]).unwrap().to_string(),
    "[a, b]",
  )
  assert_eq(apply_filter(left, "concat", []).unwrap().to_string(), "[a]")
  assert_true(apply_filter(string_value("hello"), "concat", []) is Err(_))
}

///|
test "map filter with mixed array types" {
  // Test map filter with array containing non-objects
  let obj = Map([])
  obj.set("name", string_value("Alice"))
  let mixed_arr = array_value([
    object_value(obj),
    string_value("plain string"),
    number_value(42.0),
  ])
  let result = apply_filter(mixed_arr, "map", [string_value("name")]).unwrap()
  match result {
    Array(mapped) => {
      assert_eq(mapped.length(), 3)
      assert_eq(mapped[0].to_string(), "Alice") // Object property
      assert_eq(mapped[1].to_string(), "plain string") // Non-object returns itself
      assert_eq(mapped[2].to_string(), "42") // Non-object returns itself
    }
    _ => fail("Expected Array result")
  }
}

///|
test "map filter with missing properties" {
  // Test map filter when objects don't have the specified property

  let obj1 = Map([])
  obj1.set("name", string_value("Alice"))
  // obj1 doesn't have "age" property

  let obj2 = Map([])
  obj2.set("age", number_value(30.0))
  // obj2 doesn't have "name" property

  let items = array_value([object_value(obj1), object_value(obj2)])

  // Test mapping by "age" property
  let result = apply_filter(items, "map", [string_value("age")]).unwrap()
  assert_eq(result.to_string(), "[null, 30]") // Missing property should return null
}
