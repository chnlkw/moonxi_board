///|
pub(all) enum Status[T] {
  Loading
  Failed(String)
  Success(T)
} derive(Show, Eq)
