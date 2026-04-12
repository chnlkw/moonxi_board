///|
test "Status Loading equality" {
  let a : Status[Array[Int]] = Loading
  let b : Status[Array[Int]] = Loading
  assert_true(a == b)
}

///|
test "Status Success equality" {
  let a : Status[Array[Int]] = Success([1, 2, 3])
  let b : Status[Array[Int]] = Success([1, 2, 3])
  assert_true(a == b)
}

///|
test "Status Failed equality" {
  let a : Status[Array[Int]] = Failed("err")
  let b : Status[Array[Int]] = Failed("err")
  assert_true(a == b)
}

///|
test "Status Success != Failed" {
  let a : Status[Array[Int]] = Success([1])
  let b : Status[Array[Int]] = Failed("err")
  assert_true(!(a == b))
}

///|
test "Status pattern matching returns correct value" {
  let label = (status : Status[Array[Int]]) => {
    match status {
      Loading => "loading"
      Failed(_) => "failed"
      Success(_) => "success"
    }
  }
  assert_eq(label(Loading), "loading")
  assert_eq(label(Failed("oops")), "failed")
  assert_eq(label(Success([1, 2])), "success")
}
