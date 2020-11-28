# gleam_uuid

Generate and decode UUIDs in Gleam.

Spec conformant UUID v1, v3, v4, and v5 generation.

Spec conformant UUID decoding for all versions and variants.

## Documentation
https://hexdocs.pm/gleam_uuid/

## Quick start

in your `rebar.config` deps section add:
```erlang
{gleam_uuid, "0.1.1"}
```

```rust
import gleam_uuid

// Generation
> gleam_uuid.v4_string()
"f7e321c7-4a4b-4287-a8b8-1ae35b5538ce"

// Decoding
> "f7e321c7-4a4b-4287-a8b8-1ae35b5538ce"
    |> gleam_uuid.from_string()
    |> result.map(gleam_uuid.version)
Ok(gleam_uuid.V4)
```
