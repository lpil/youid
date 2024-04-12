//// Spec conformant UUID v1, v3, v4, and v5 generation.
////
//// Spec conformant UUID decoding for all versions and variants.
////
//// Spec: [https://www.ietf.org/rfc/rfc4122.txt](https://www.ietf.org/rfc/rfc4122.txt)
////
//// Wikipedia: [https://en.wikipedia.org/wiki/uuid](https://en.wikipedia.org/wiki/uuid)
////
//// Unless you have a specific reason otherwise, you probably either want the
//// random v4 or the time-based v1 version.

import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/list
import gleam/string

// uuid's epoch is 15 Oct 1582, that's this many 100ns intervals until 1 Jan 1970.
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

const v7_version = 7

/// Opaque type for holding onto a UUID.
/// Opaque so you know that if you have a UUID it is valid.
pub opaque type Uuid {
  Uuid(value: BitArray)
}

/// Possible UUID versions.
/// This library only creates V1, V3, V4, V5, and V7 UUIDs but can decode all versions
pub type Version {
  V1
  V2
  V3
  V4
  V5
  V7
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
  CustomClockSeq(BitArray)
}

/// Create a V1 (time-based) UUID with default node and random clock sequence.
pub fn v1() -> Uuid {
  do_v1(default_uuid1_node(), random_uuid1_clockseq())
}

/// Convenience for quickly creating a time-based UUID String with default settings.
pub fn v1_string() -> String {
  v1()
  |> to_string()
}

/// Create a V1 (time-based) UUID with custom node and clock sequence.
pub fn v1_custom(node: V1Node, clock_seq: V1ClockSeq) -> Result(Uuid, Nil) {
  case validate_node(node), validate_clock_seq(clock_seq) {
    Ok(n), Ok(cs) -> Ok(do_v1(n, cs))
    _, _ -> Error(Nil)
  }
}

fn do_v1(node, clock_seq) -> Uuid {
  let assert <<node:48>> = node
  let assert <<time_hi:12, time_mid:16, time_low:32>> = uuid1_time()
  let assert <<clock_seq:14>> = clock_seq
  let value = <<
    time_low:32,
    time_mid:16,
    v1_version:4,
    time_hi:12,
    rfc_variant:2,
    clock_seq:14,
    node:48,
  >>

  Uuid(value: value)
}

fn validate_node(node: V1Node) -> Result(BitArray, Nil) {
  case node {
    DefaultNode -> Ok(default_uuid1_node())
    RandomNode -> Ok(random_uuid1_node())
    CustomNode(str) -> validate_custom_node(str, 0, <<>>)
  }
}

fn validate_custom_node(
  str: String,
  index: Int,
  acc: BitArray,
) -> Result(BitArray, Nil) {
  case string.pop_grapheme(str) {
    Error(Nil) if index == 12 -> Ok(acc)
    Ok(#(":", rest)) -> validate_custom_node(rest, index, acc)
    Ok(#(c, rest)) ->
      case hex_to_int(c) {
        Ok(i) if index < 12 ->
          validate_custom_node(rest, index + 1, <<acc:bits, i:4>>)
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn validate_clock_seq(clock_seq: V1ClockSeq) -> Result(BitArray, Nil) {
  case clock_seq {
    RandomClockSeq -> Ok(random_uuid1_clockseq())
    CustomClockSeq(bs) ->
      case bit_size(bs) == 14 {
        True -> Ok(bs)
        False -> Error(Nil)
      }
  }
}

// See 4.1.4.  Timestamp in RFC 4122
// 60 bit timestamp of 100ns intervals since 00:00:00.00, 15 October 1582
fn uuid1_time() -> BitArray {
  let #(mega_sec, sec, micro_sec) = os_timestamp()
  let epoch = mega_sec * 1_000_000_000_000 + sec * 1_000_000 + micro_sec
  let timestamp = nanosec_intervals_offset + nanosec_intervals_factor * epoch
  <<timestamp:size(60)>>
}

// Generate random clock sequence
fn random_uuid1_clockseq() -> BitArray {
  let assert <<clock_seq:size(14), _:size(2)>> = crypto.strong_random_bytes(2)
  <<clock_seq:size(14)>>
}

// Get local IEEE 802 (MAC) address, or generate a random one
// Asks erlang for a list of network interfaces, the first one
// with a valid hwaddr, that hwaddr is used. If no valid hwaddrs
// are found a random MAC is generated
fn default_uuid1_node() -> BitArray {
  case mac_address() {
    Ok(node) -> node
    _ -> random_uuid1_node()
  }
}

fn random_uuid1_node() -> BitArray {
  let assert <<rnd_hi:size(7), _:size(1), rnd_low:size(40)>> =
    crypto.strong_random_bytes(6)
  <<rnd_hi:size(7), 1:size(1), rnd_low:size(40)>>
}

//
// V3
//
/// Generates a version 3 (name-based, md5 hashed) UUID.
/// Name must be a valid sequence of bytes
pub fn v3(namespace: Uuid, name: BitArray) -> Result(Uuid, Nil) {
  case bit_size(name) % 8 == 0 {
    True ->
      <<namespace.value:bits, name:bits>>
      |> md5()
      |> hash_to_uuid_value(v3_version)
      |> Uuid
      |> Ok
    False -> Error(Nil)
  }
}

fn md5(data: BitArray) -> BitArray {
  crypto.hash(crypto.Md5, data)
}

fn hash_to_uuid_value(hash: BitArray, ver: Int) -> BitArray {
  let assert <<
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
pub fn v4() -> Uuid {
  let assert <<a:size(48), _:size(4), b:size(12), _:size(2), c:size(62)>> =
    crypto.strong_random_bytes(16)

  let value = <<
    a:size(48),
    v4_version:size(4),
    b:size(12),
    rfc_variant:size(2),
    c:size(62),
  >>

  Uuid(value: value)
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
pub fn v5(namespace: Uuid, name: BitArray) -> Result(Uuid, Nil) {
  case bit_size(name) % 8 == 0 {
    True ->
      <<namespace.value:bits, name:bits>>
      |> sha1()
      |> hash_to_uuid_value(v5_version)
      |> Uuid
      |> Ok
    False -> Error(Nil)
  }
}

fn sha1(data: BitArray) -> BitArray {
  let assert <<sha:128, _:32>> = crypto.hash(crypto.Sha1, data)
  <<sha:128>>
}

//
// V7
//
/// Generates a version 7 (timestamp-based) UUID.
pub fn v7() -> Uuid {
  let ms = system_time(1000)
  custom_v7(ms)
}

/// Creates a version 7 UUID from a specific timestamp.
/// Integer should be milliseconds from UNIX epoch.
pub fn custom_v7(timestamp: Int) -> Uuid {
  let assert <<a:size(12), b:size(62), _:size(6)>> =
    crypto.strong_random_bytes(10)
  let value = <<timestamp:48, v7_version:4, a:12, rfc_variant:2, b:62>>
  Uuid(value: value)
}

/// Convenience function for quickly creating a timestamp-based
/// version 7 UUID
pub fn v7_string() -> String {
  v7()
  |> format(String)
}

//
// More public interface
//
/// Determine the Version of a UUID
pub fn version(uuid: Uuid) -> Version {
  let assert <<_:48, ver:4, _:76>> = uuid.value
  decode_version(ver)
}

/// Determine the Variant of a UUID
pub fn variant(uuid: Uuid) -> Variant {
  let assert <<_:64, var:3, _:61>> = uuid.value
  decode_variant(<<var:3>>)
}

/// Determine the time a UUID was created with Gregorian Epoch
/// This is only relevant to a V1 UUID
/// UUID's use 15 Oct 1582 as Epoch and time is measured in 100ns intervals.
/// This value is useful for comparing V1 UUIDs but not so much for
/// telling what time a UUID was created. See time_posix_microsec and clock_sequence
pub fn time(uuid: Uuid) -> Int {
  let assert <<t_low:32, t_mid:16, _:4, t_hi:12, _:64>> = uuid.value
  let assert <<t:60>> = <<t_hi:12, t_mid:16, t_low:32>>
  t
}

/// Determine the time a UUID was created with Unix Epoch
/// This is only relevant to a V1 UUID
/// Value is the number of micro seconds since Unix Epoch
pub fn time_posix_microsec(uuid: Uuid) -> Int {
  { time(uuid) - nanosec_intervals_offset } / nanosec_intervals_factor
}

/// Determine the clock sequence of a UUID
/// This is only relevant to a V1 UUID
pub fn clock_sequence(uuid: Uuid) -> Int {
  let assert <<_:66, clock_seq:14, _:48>> = uuid.value
  clock_seq
}

/// Determine the node of a UUID
/// This is only relevant to a V1 UUID
pub fn node(uuid: Uuid) -> String {
  let assert <<
    _:80,
    a:4,
    b:4,
    c:4,
    d:4,
    e:4,
    f:4,
    g:4,
    h:4,
    i:4,
    j:4,
    k:4,
    l:4,
  >> = uuid.value
  [a, b, c, d, e, f, g, h, i, j, k, l]
  |> list.map(int.to_base16)
  |> string.concat()
}

/// Determine the time a UUID was created with Unix Epoch
/// This is only relevant to a V7 UUID
/// Value is the number of milliseconds since Unix Epoch
pub fn time_posix_millisecond(uuid: Uuid) -> Int {
  let assert <<t:48, _:80>> = uuid.value
  t
}

/// Convert a UUID to a standard string
pub fn to_string(uuid: Uuid) -> String {
  format(uuid, String)
}

/// Convert a UUID to one of the supported string formats
pub fn format(uuid: Uuid, format: Format) -> String {
  let separator = case format {
    String -> "-"
    _ -> ""
  }

  let start = case format {
    Urn -> urn_id
    _ -> ""
  }

  to_string_help(uuid.value, 0, start, separator)
}

fn to_string_help(
  ints: BitArray,
  position: Int,
  acc: String,
  separator: String,
) -> String {
  case position {
    8 | 13 | 18 | 23 ->
      to_string_help(ints, position + 1, acc <> separator, separator)
    _ ->
      case ints {
        <<i:size(4), rest:bits>> -> {
          to_string_help(rest, position + 1, acc <> int.to_base16(i), separator)
        }
        _ -> acc
      }
  }
}

/// Attempt to decode a UUID from a string. Supports strings formatted in the same
/// ways this library will output them. Hex with dashes, hex without dashes and
/// hex with or without dashes prepended with "urn:uuid:"
pub fn from_string(in: String) -> Result(Uuid, Nil) {
  let hex = case in {
    "urn:uuid:" <> in -> in
    _ -> in
  }

  case to_bit_array_helper(hex) {
    Ok(bits) -> Ok(Uuid(value: bits))
    Error(_) -> Error(Nil)
  }
}

//
// Builtin UUIDs
//
/// dns namespace UUID provided by the spec, only useful for v3 and v5
pub fn dns_uuid() -> Uuid {
  Uuid(value: <<143_098_242_404_177_361_603_877_621_312_831_893_704:128>>)
}

/// url namespace UUID provided by the spec, only useful for v3 and v5
pub fn url_uuid() -> Uuid {
  Uuid(value: <<143_098_242_483_405_524_118_141_958_906_375_844_040:128>>)
}

/// oid namespace UUID provided by the spec, only useful for v3 and v5
pub fn oid_uuid() -> Uuid {
  Uuid(value: <<143_098_242_562_633_686_632_406_296_499_919_794_376:128>>)
}

/// x500 namespace UUID provided by the spec, only useful for v3 and v5
pub fn x500_uuid() -> Uuid {
  Uuid(value: <<143_098_242_721_090_011_660_934_971_687_007_695_048:128>>)
}

/// Convert a UUID to a bit array
pub fn to_bit_array(uuid: Uuid) -> BitArray {
  uuid.value
}

/// Attemts to convert a bit array to a UUID.
/// Will fail if the bit array is not 16 bytes long or has an invalid version.
pub fn from_bit_array(bit_array: BitArray) -> Result(Uuid, Nil) {
  let uuid = Uuid(bit_array)

  case bit_array.byte_size(bit_array) {
    16 ->
      case version(uuid) {
        VUnknown -> Error(Nil)
        _ -> Ok(uuid)
      }
    _ -> Error(Nil)
  }
}

//
// helpers
//
fn to_bit_array_helper(str: String) -> Result(BitArray, Nil) {
  to_bitstring_help(str, 0, <<>>)
}

fn to_bitstring_help(
  str: String,
  index: Int,
  acc: BitArray,
) -> Result(BitArray, Nil) {
  case string.pop_grapheme(str) {
    Error(Nil) if index == 32 -> Ok(acc)
    Ok(#("-", rest)) if index < 32 -> to_bitstring_help(rest, index, acc)
    Ok(#(c, rest)) if index < 32 ->
      case hex_to_int(c) {
        Ok(i) -> to_bitstring_help(rest, index + 1, <<acc:bits, i:size(4)>>)
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
    7 -> V7
    _ -> VUnknown
  }
}

fn decode_variant(variant_bits: BitArray) -> Variant {
  case variant_bits {
    <<1:size(1), 1:size(1), 1:size(1)>> -> ReservedFuture
    <<1:size(1), 1:size(1), 0:size(1)>> -> ReservedMicrosoft
    <<1:size(1), 0:size(1), _:size(1)>> -> Rfc4122
    <<0:size(1), _:size(1), _:size(1)>> -> ReservedNcs
    _ -> ReservedNcs
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

// Erlang Bridge
@external(erlang, "youid_ffi", "mac_address")
fn mac_address() -> Result(BitArray, Nil)

@external(erlang, "os", "timestamp")
fn os_timestamp() -> #(Int, Int, Int)

@external(erlang, "os", "system_time")
fn system_time(second_division: Int) -> Int

// TODO: add this to the stdlib
@external(erlang, "erlang", "bit_size")
fn bit_size(bs: BitArray) -> Int
