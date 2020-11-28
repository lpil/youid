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

in a Gleam module:
```rust
import gleam_uuid

let my_random_uuid:String = gleam_uuid.v4_string()
```
