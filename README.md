# gleam_uuid

Generate and decode UUIDs in Gleam.

Supports decoding all versions of UUIDs and generating of V1, V3, V4, and V5 UUIDs.

## Documentation
https://hexdocs.pm/gleam_uuid/

## Quick start

in your `rebar.config` deps section add:
```erlang
{gleam_uuid, "0.1.0"}
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
