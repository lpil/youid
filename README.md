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
  uuid.v4_string()
  // -> "f55f6957-534b-45a7-af22-a1591431bc1f"
}
```

Spec conformant UUID v1, v3, v4, and v5 generation.

Spec conformant UUID decoding for v1, v2, v3, v4, and v5.

Spec: [https://www.ietf.org/rfc/rfc4122.txt](https://www.ietf.org/rfc/rfc4122.txt)

Wikipedia: [https://en.wikipedia.org/wiki/uuid](https://en.wikipedia.org/wiki/uuid)

Unless you have a specific reason otherwise, you probably either want the
random v4 or the time-based v1 version.

Currently this library only works on the Erlang target as the JavaScript target
does not yet support non-byte aligned bit arrays.

Further documentation can be found at <https://hexdocs.pm/youid>.

Many thanks to Gregggreg for [the original version][original] of this library.

[original]: https://gitlab.com/greggreg/gleam_uuid
