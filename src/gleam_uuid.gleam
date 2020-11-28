//// Spec conformant UUID v1, v3-v5 generation and decoding.
////
//// Spec: [https://www.ietf.org/rfc/rfc4122.txt](https://www.ietf.org/rfc/rfc4122.txt)
////
//// Wikipedia: [https://en.wikipedia.org/wiki/uuid](https://en.wikipedia.org/wiki/uuid)
////
//// Unless you have a specific reason otherwise, you probably want the random
//// variant, V4.
//// 
//// ## Quick Usage:
////
////    import gleam_uuid
////
////    gleam_uuid.v4_string() 

import gleam/bit_builder.{BitBuilder}
import gleam/bit_string.{BitString}
import gleam/list
import gleam/string
import gleam/atom.{Atom}
import gleam/dynamic.{Dynamic}
import gleam/result

// uuid's epoch is 15 Oct 1582, that's this many 100ns intervals until 1 Jan 1970.
///
const nanosec_intervals_offset = 122_192_928_000_000_000

// Microseconds to nanosecond interval factor.
const nanosec_intervals_factor = 10

// Use like: <<variant:size(2)>> AKA <<1:size(1), 0:size(1)>>
const rfc_variant = 2

const urn_id = "urn:uuid:"

const v1_version = 1

const v3_version = 3

const v4_version = 4

const v5_version = 5

/// Opaque type for holding onto a UUID.
/// Opaque so you know that if you have a UUID it is valid.
pub opaque type UUID {
  UUID(value: BitString)
}

/// Possible UUID versions.
/// This library only creates V1, V3, V4 and V5 UUIDs but can decode all versions
pub type Version {
  V1
  V2
  V3
  V4
  V5
  VUnknown
}

/// Possible UUID variants.
/// This library only produces Rfc4122 variant UUIDs but can decode all variants
pub type Variant {
  ReservedFuture
  ReservedMicrosoft
  ReservedNcs
  Rfc4122
}

/// Supported string formats
pub type Format {
  /// Standad hex string with dashes
  String
  /// Hex string with no dashes
  Hex
  /// Standard hex string with dashes prepended with "urn:uuid:"
  Urn
}

// 
// V1
// 
/// How to generate the node for a V1 UUID.
pub type V1Node {
  /// Will first attempt to use the network cards MAC address, then fall back to random
  DefaultNode
  /// Will be random
  RandomNode
  /// Will be the provided sting, must be 12 characters long and valid hex
  CustomNode(String)
}

/// How to generate the clock sequence for a V1 UUID
pub type V1ClockSeq {
  /// Will be generated randomly.
  RandomClockSeq
  /// Will be the provided bit string, must be exactly 14 bits.
  CustomClockSeq(BitString)
}

/// Create a V1 (time-based) UUID with default node and random clock sequence.
pub fn v1() -> UUID {
  do_v1(default_uuid1_node(), random_uuid1_clockseq())
}

/// Create a V1 (time-based) UUID with custom node and clock sequence.
pub fn v1_custom(node: V1Node, clock_seq: V1ClockSeq) -> Result(UUID, Nil) {
  case validate_node(node), validate_clock_seq(clock_seq) {
    Ok(n), Ok(cs) -> Ok(do_v1(n, cs))
    _, _ -> Error(Nil)
  }
}

fn do_v1(node, clock_seq) -> UUID {
  assert <<node:48>> = node
  assert <<time_hi:12, time_mid:16, time_low:32>> = uuid1_time()
  assert <<clock_seq:14>> = clock_seq
  let value = <<
    time_low:32,
    time_mid:16,
    v1_version:4,
    time_hi:12,
    rfc_variant:2,
    clock_seq:14,
    node:48,
  >>

  UUID(value: value)
}

fn validate_node(node: V1Node) -> Result(BitString, Nil) {
  case node {
    DefaultNode -> Ok(default_uuid1_node())
    RandomNode -> Ok(random_uuid1_node())
    CustomNode(str) ->
      validate_custom_node(str, 0, bit_builder.from_string(""))
      |> result.map(bit_builder.to_bit_string)
  }
}

fn validate_custom_node(
  str: String,
  index: Int,
  acc: BitBuilder,
) -> Result(BitBuilder, Nil) {
  case string.pop_grapheme(str) {
    Error(Nil) if index == 12 -> Ok(acc)
    Ok(tuple(":", rest)) -> validate_custom_node(rest, index, acc)
    Ok(tuple(c, rest)) ->
      case hex_to_int(c) {
        Ok(i) if index < 12 ->
          validate_custom_node(
            rest,
            index + 1,
            bit_builder.append(acc, <<i:4>>),
          )
        Error(_) -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn validate_clock_seq(clock_seq: V1ClockSeq) -> Result(BitString, Nil) {
  case clock_seq {
    RandomClockSeq -> Ok(random_uuid1_clockseq())
    CustomClockSeq(bs) ->
      case bit_size(bs) == 14 {
        True -> Ok(bs)
        False -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

// See 4.1.4.  Timestamp in RFC 4122
// 60 bit timestamp of 100ns intervals since 00:00:00.00, 15 October 1582
fn uuid1_time() -> BitString {
  let tuple(mega_sec, sec, micro_sec) = os_timestamp()
  let epoch = mega_sec * 1_000_000_000_000 + sec * 1_000_000 + micro_sec
  let timestamp = nanosec_intervals_offset + nanosec_intervals_factor * epoch
  <<timestamp:size(60)>>
}

// Generate random clock sequence
fn random_uuid1_clockseq() -> BitString {
  let <<clock_seq:size(14), _:size(2)>> = strong_rand_bytes(2)
  <<clock_seq:size(14)>>
}

// Get local IEEE 802 (MAC) address, or generate a random one
// Asks erlang for a list of network interfaces, the first one
// with a valid hwaddr, that hwaddr is used. If no valid hwaddrs
// are found a random MAC is generated
fn default_uuid1_node() -> BitString {
  case inet_getifaddrs() {
    Ok(ifs) ->
      case find_uuid1_node(ifs) {
        Ok(node) -> node
        _ -> random_uuid1_node()
      }
    _ -> random_uuid1_node()
  }
}

fn find_uuid1_node(ifs) -> Result(BitString, Nil) {
  case ifs {
    [] -> Error(Nil)
    [tuple(_name, props), ..rest] ->
      case list.key_find(props, atom.create_from_string("hwaddr")) {
        Ok(ints) ->
          case list.length(ints) != 0 || list.all(ints, fn(x) { x == 0 }) {
            True -> find_uuid1_node(rest)
            False -> Ok(ints_to_bitstring(ints))
          }
        _ -> find_uuid1_node(rest)
      }
  }
}

fn random_uuid1_node() -> BitString {
  assert <<rnd_hi:size(7), _:size(1), rnd_low:size(40)>> = strong_rand_bytes(6)
  <<rnd_hi:size(7), 1:size(1), rnd_low:size(40)>>
}

//
// V3
//
/// Generates a version 3 (name-based, md5 hashed) UUID.
/// Name must be a valid sequence of bytes
pub fn v3(namespace: UUID, name: BitString) -> Result(UUID, Nil) {
  case bit_size(name) % 8 == 0 {
    True ->
      namespace.value
      |> bit_builder.from_bit_string()
      |> bit_builder.append(name)
      |> bit_builder.to_bit_string()
      |> md5()
      |> hash_to_uuid_value(v3_version)
      |> UUID
      |> Ok
    False -> Error(Nil)
  }
}

fn md5(data: BitString) -> BitString {
  crypto_hash(atom.create_from_string("md5"), data)
}

fn hash_to_uuid_value(hash: BitString, ver: Int) -> BitString {
  assert <<
    time_low:32,
    time_mid:16,
    _:4,
    time_hi:12,
    _:2,
    clock_seq_hi:6,
    clock_seq_low:8,
    node:48,
  >> = hash

  <<
    time_low:32,
    time_mid:16,
    ver:4,
    time_hi:12,
    rfc_variant:2,
    clock_seq_hi:6,
    clock_seq_low:8,
    node:48,
  >>
}

//
// V4
//
/// Generates a version 4 (random) UUID.
pub fn v4() -> UUID {
  assert <<a:size(48), _:size(4), b:size(12), _:size(2), c:size(62)>> =
    strong_rand_bytes(16)

  let value = <<
    a:size(48),
    v4_version:size(4),
    b:size(12),
    rfc_variant:size(2),
    c:size(62),
  >>

  UUID(value: value)
}

/// Convenience for quickly creating a random UUID String
pub fn v4_string() -> String {
  v4()
  |> format(String)
}

//
// V5
//
/// Generates a version 5 (name-based, sha1 hashed) UUID.
/// name must be a valid sequence of bytes
pub fn v5(namespace: UUID, name: BitString) -> Result(UUID, Nil) {
  case bit_size(name) % 8 == 0 {
    True ->
      namespace.value
      |> bit_builder.from_bit_string()
      |> bit_builder.append(name)
      |> bit_builder.to_bit_string()
      |> sha1()
      |> hash_to_uuid_value(v5_version)
      |> UUID
      |> Ok
    False -> Error(Nil)
  }
}

fn sha1(data: BitString) -> BitString {
  assert <<sha:128, _:32>> = crypto_hash(atom.create_from_string("sha"), data)
  <<sha:128>>
}

//
// More public interface
//
/// Determine the Version of a UUID
pub fn version(uuid: UUID) -> Version {
  assert <<_:48, ver:4, _:76>> = uuid.value
  decode_version(ver)
}

/// Determine the Variant of a UUID
pub fn variant(uuid: UUID) -> Variant {
  assert <<_:64, var:3, _:61>> = uuid.value
  decode_variant(<<var:3>>)
}

/// Determine the time a UUID was created with Gregorian Epoch
/// This is only relevant to a V1 UUID
/// UUID's use 15 Oct 1582 as Epoch and time is measured in 100ns intervals.
/// This value is useful for comparing V1 UUIDs but not so much for
/// telling what time a UUID was created. See time_posix_microsec and clock_sequence
pub fn time(uuid: UUID) -> Int {
  assert <<t_low:32, t_mid:16, _:4, t_hi:12, _:64>> = uuid.value
  assert <<t:60>> = <<t_hi:12, t_mid:16, t_low:32>>
  t
}

/// Determine the time a UUID was created with Unix Epoch
/// This is only relevant to a V1 UUID
/// Value is the number of micro seconds since Unix Epoch
pub fn time_posix_microsec(uuid: UUID) -> Int {
  { time(uuid) - nanosec_intervals_offset } / nanosec_intervals_factor
}

/// Determine the clock sequence of a UUID
/// This is only relevant to a V1 UUID
pub fn clock_sequence(uuid: UUID) -> Int {
  assert <<_:66, clock_seq:14, _:48>> = uuid.value
  clock_seq
}

/// Determine the node of a UUID
/// This is only relevant to a V1 UUID
pub fn node(uuid: UUID) -> String {
  assert <<_:80, a:4, b:4, c:4, d:4, e:4, f:4, g:4, h:4, i:4, j:4, k:4, l:4>> =
    uuid.value
  [a, b, c, d, e, f, g, h, i, j, k, l]
  |> list.map(int_to_hex)
  |> string.concat()
}

/// Convert a UUID to a standard string
pub fn to_string(uuid: UUID) -> String {
  format(uuid, String)
}

/// Convert a UUID to one of the supported string formats
pub fn format(uuid: UUID, format: Format) -> String {
  let separator = case format {
    String -> "-"
    _ -> ""
  }

  let start = case format {
    Urn -> [urn_id]
    _ -> []
  }

  to_string_help(uuid.value, 0, start, separator)
}

fn to_string_help(
  ints: BitString,
  position: Int,
  acc: List(String),
  separator: String,
) -> String {
  case position {
    8 | 13 | 18 | 23 ->
      to_string_help(ints, position + 1, [separator, ..acc], separator)
    _ ->
      case ints {
        <<i:size(4), rest:bit_string>> ->
          to_string_help(rest, position + 1, [int_to_hex(i), ..acc], separator)
        <<>> ->
          acc
          |> list.reverse()
          |> string.concat()
      }
  }
}

/// Attempt to decode a UUID from a string. Supports strings formatted in the same
/// ways this library will output them. Hex with dashes, hex without dashes and
/// hex with or without dashes prepended with "urn:uuid:"
pub fn from_string(in: String) -> Result(UUID, Nil) {
  let hex = case string.starts_with(in, urn_id) {
    True -> string.drop_left(in, 9)
    False -> in
  }

  case to_bitstring(hex) {
    Ok(bits) -> Ok(UUID(value: bits))
    Error(_) -> Error(Nil)
  }
}

//
// Builtin UUIDs
//
/// dns namespace UUID provided by the spec, only useful for v3 and v5
pub fn dns_uuid() -> UUID {
  UUID(value: <<143098242404177361603877621312831893704:128>>)
}

/// url namespace UUID provided by the spec, only useful for v3 and v5
pub fn url_uuid() -> UUID {
  UUID(value: <<143098242483405524118141958906375844040:128>>)
}

/// oid namespace UUID provided by the spec, only useful for v3 and v5
pub fn oid_uuid() -> UUID {
  UUID(value: <<143098242562633686632406296499919794376:128>>)
}

/// x500 namespace UUID provided by the spec, only useful for v3 and v5
pub fn x500_uuid() -> UUID {
  UUID(value: <<143098242721090011660934971687007695048:128>>)
}

//
// helpers
//
fn to_bitstring(str: String) -> Result(BitString, Nil) {
  str
  |> to_bitstring_help(0, bit_builder.from_string(""))
  |> result.map(bit_builder.to_bit_string)
}

fn to_bitstring_help(
  str: String,
  index: Int,
  acc: BitBuilder,
) -> Result(BitBuilder, Nil) {
  case string.pop_grapheme(str) {
    Error(Nil) if index == 32 -> Ok(acc)
    Ok(tuple("-", rest)) if index < 32 -> to_bitstring_help(rest, index, acc)
    Ok(tuple(c, rest)) if index < 32 ->
      case hex_to_int(c) {
        Ok(i) ->
          to_bitstring_help(
            rest,
            index + 1,
            bit_builder.append(acc, <<i:size(4)>>),
          )
        Error(_) -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn decode_version(int: Int) -> Version {
  case int {
    1 -> V1
    2 -> V2
    3 -> V3
    4 -> V4
    5 -> V5
    _ -> VUnknown
  }
}

fn decode_variant(variant_bits: BitString) -> Variant {
  case variant_bits {
    <<1:size(1), 1:size(1), 1:size(1)>> -> ReservedFuture
    <<1:size(1), 1:size(1), 0:size(1)>> -> ReservedMicrosoft
    <<1:size(1), 0:size(1), _:size(1)>> -> Rfc4122
    <<0:size(1), _:size(1), _:size(1)>> -> ReservedNcs
  }
}

// Hex Helpers
fn hex_to_int(c: String) -> Result(Int, Nil) {
  let i = case c {
    "0" -> 0
    "1" -> 1
    "2" -> 2
    "3" -> 3
    "4" -> 4
    "5" -> 5
    "6" -> 6
    "7" -> 7
    "8" -> 8
    "9" -> 9
    "a" | "A" -> 10
    "b" | "B" -> 11
    "c" | "C" -> 12
    "d" | "D" -> 13
    "e" | "E" -> 14
    "f" | "F" -> 15
    _ -> 16
  }
  case i {
    16 -> Error(Nil)
    x -> Ok(x)
  }
}

fn int_to_hex(int: Int) -> String {
  integer_to_binary(int, 16)
}

// Erlang Bridge
external fn strong_rand_bytes(Int) -> String =
  "crypto" "strong_rand_bytes"

external fn integer_to_binary(Int, Int) -> String =
  "erlang" "integer_to_binary"

external fn os_timestamp() -> tuple(Int, Int, Int) =
  "os" "timestamp"

// TODO: This Dynamic is an erlang posix(). Does that exist in Gleam somewhere?
// see: http://erlang.org/doc/man/file.html#type-posix
// TODO: The return type is more dynamic than stated, we only care about one
// particular key though that will always be the type we're looking for, change?
external fn inet_getifaddrs() -> Result(
  List(tuple(String, List(tuple(Atom, List(Int))))),
  Dynamic,
) =
  "inet" "getifaddrs"

external fn ints_to_bitstring(List(Int)) -> BitString =
  "erlang" "list_to_binary"

external fn crypto_hash(algo: Atom, data: BitString) -> BitString =
  "crypto" "hash"

external fn bit_size(bs: BitString) -> Int =
  "erlang" "bit_size"
