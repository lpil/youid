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

  // Convert it a URL-safe compact text format
  uuid.to_base64(id)
  // -> "AZ1EnCyCcbu0v2UF33rXwg"
}
```

Spec conformant UUID v1, v3, v4, v5, and v7 generation.

Spec conformant UUID decoding for v1, v2, v3, v4, v5, and v7.

Spec: [https://www.ietf.org/rfc/rfc9562.txt](https://www.ietf.org/rfc/rfc9562.txt)

Wikipedia: [https://en.wikipedia.org/wiki/uuid](https://en.wikipedia.org/wiki/uuid)

Unless you have a specific reason otherwise, you probably either want the
random v4 or the time-based v1 or v7 versions.

Further documentation can be found at <https://hexdocs.pm/youid>.

Many thanks to Gregggreg for [the original version][original] of this library.

[original]: https://gitlab.com/greggreg/gleam_uuid
