//// This module provides the little bit of boilerplate you're liekly 
//// to want to write around your UUIDs.
//// It provides a type `Id` which:
//// 1. is a wrapper around a UUID
//// 2. has a phantom type to ensure that the ID is used in the correct context.
//// 3. provides a prefix to the ID.
//// 4. provides a function to generate IDs of the specified type
//// 
//// Let's say you have a type `User` which you want to provide IDs for. 
//// Just set up your function for generating new ids like so
//// 
//// ```gleam
//// // Your Type
//// pub type User
////
//// // Your specification for creating new IDs
//// pub fn new_user_id() -> Id(User) {
////   id.format(prefixed_with: "orgname-user")()
//// }
//// ```

import youid/uuid.{type Uuid}

/// A high level wrapper around a Uuid with some common functionality.
/// 1. a phantom type to ensure that the ID is used in the correct context.
/// 2. provide a prefix to the ID.
pub opaque type Id(a) {
  Id(String)
}

/// Get out the inner string of the ID.
pub fn to_string(id: Id(a)) -> String {
  let Id(value) = id
  value
}

/// A function which will generate IDs of the specified type
pub type IdGenerator(a) =
  fn() -> Id(a)

/// Create a new ID generator which will generate IDs with the specified prefix.
///
pub fn format(prefixed_with prefix: String) -> IdGenerator(a) {
  fn() {
    let id = uuid.v4_string()
    Id(prefix <> "-" <> id)
  }
}
