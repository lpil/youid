# youid

Generate and parse UUIDs.

[![Package Version](https://img.shields.io/hexpm/v/youid)](https://hex.pm/packages/youid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/youid/)

```sh
gleam add youid
```

```gleam
import youid/uuid

pub fn main() {
  // Generate a universally-unique identifier
  let id = uuid.v7()

  // Convert it to the standard text format
  uuid.to_string(id)
  // -> "019d449c-2c82-71bb-b4bf-6505df7ad7c2"

  // Convert it to a compact text format, good for user interfaces
  uuid.to_base64(id)
  // -> "AZ1EnCyCcbu0v2UF33rXwg"

  // Convert it to a compact tagged format, good for APIs
  uuid.to_tagged(id, "order")
  // -> "order_AZ1EnCyCcbu0v2UF33rXwg"
}
```

In an API you may want to use the tagged id format, which is compact and has a
tag prefix, making it easy to know what resource it is for.

```gleam
import app/userbase.{type User}
import gleam/json.{type Json}
import gleam/dynamic/decoder.{type Decoder}
import tagged_id

pub fn user_to_json(user: User) -> Json {
  // Convert a UUID to the tagged-id format
  let id = tagged_id.format(user.id, "user")

  // You can use it in JSON, for example.
  json.object([
    #("id", json.string(id)),
    #("name", json.string(name)),
  ])
}

pub fn user_decoder() -> Decoder(User) {
  // Decode an id in the tagged-id format
  use id <- decode.field("id", tagged_id.decoder("user"))
  use name <- decode.field("name", decode.string)
  decode.success(User(id:, name:))
}
```

Spec conformant UUID v1, v3, v4, v5, and v7 generation.

Spec conformant UUID decoding for v1, v2, v3, v4, v5, and v7.

Spec: [https://www.ietf.org/rfc/rfc9562.txt](https://www.ietf.org/rfc/rfc9562.txt)

Wikipedia: [https://en.wikipedia.org/wiki/uuid](https://en.wikipedia.org/wiki/uuid)

Unless you have a specific reason otherwise, you probably want v7.

Further documentation can be found at <https://hexdocs.pm/youid>.

Many thanks to Greggreg for [the original version][original] of this library.

[original]: https://gitlab.com/greggreg/gleam_uuid
