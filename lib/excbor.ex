defrecord CBOR.Tag, tag: nil, value: nil
defrecord CBOR.Decoder.Treatment.Map,
                            newmap: &CBOR.default_newmap/0,
                            add_to_map: &CBOR.default_add_to_map/3,
                            finish_map: &CBOR.default_finish_map/1,
                            empty_map: &CBOR.default_empty_map/0
defrecord CBOR.Decoder.Treatment,
                  text: &CBOR.identity/1,
                  bytes: &CBOR.mark_as_bytes/1,
                  nonfinites: &CBOR.decode_non_finite/2,
                  map: CBOR.Decoder.Treatment.Map.new,
                  tags: []
defmodule CBOR do
  def decode_non_finite(0, 0), do: {CBOR.Tag, :float, :inf}
  def decode_non_finite(1, 0), do: {CBOR.Tag, :float, :"-inf"}
  def decode_non_finite(_, _), do: {CBOR.Tag, :float, :nan}
  def default_newmap(), do: []
  def default_add_to_map(map, k, v), do: [{k,v}|map]
  def default_finish_map(map), do: Enum.reverse(map)
  def default_empty_map(), do: [{}]
  def hash_add_to_map(map, k, v), do: HashDict.put(map, k, v)
  def hash_empty_map(), do: HashDict.new
  def identity(x), do: x
  def mark_as_bytes({x,rest}), do: {{CBOR.Tag, :bytes, x}, rest}
  @default_treatment CBOR.Decoder.Treatment.new
  @hash_treatment_map CBOR.Decoder.Treatment.Map[
                              newmap: &CBOR.hash_empty_map/0,
                              add_to_map: &CBOR.hash_add_to_map/3,
                              finish_map: &CBOR.identity/1,
                              empty_map: &CBOR.hash_empty_map/0]
  @hash_treatment CBOR.Decoder.Treatment[map: @hash_treatment_map]
  def decode_header(<< mt::size(3), val::size(5),
                    rest::binary >>) when val < 24, do: {mt, val, rest}
  def decode_header(<< mt::size(3), 24::size(5),
                    val::[unsigned, size(8)], rest::binary >>), do: {mt, val, rest}
  def decode_header(<< mt::size(3), 25::size(5),
                    val::[unsigned, size(16)], rest::binary >>), do: {mt, val, rest}
  def decode_header(<< mt::size(3), 26::size(5),
                    val::[unsigned, size(32)], rest::binary >>), do: {mt, val, rest}
  def decode_header(<< mt::size(3), 27::size(5),
                    val::[unsigned, size(64)], rest::binary >>), do: {mt, val, rest}
  def decode_header(<< mt::size(3), 31::size(5), rest::binary >>), do: {mt, :indefinite, rest}
  def decode_with_hashes(bin), do: decode(bin, @hash_treatment)
  def decode(bin, treatment // @default_treatment) do
    {term, ""} = decode_with_rest(bin, treatment)
    term
  end
  def decode_with_hashes_with_rest(bin), do: decode_with_rest(bin, @hash_treatment)
  def decode_with_rest(bin, treatment // @default_treatment) do
    {mt, val, rest} = decode_header(bin)
    case val do
      :indefinite ->
        case mt do
          2 -> treatment.bytes.(decode_string_indefinite(rest, 2, []))
          3 -> treatment.text.(decode_string_indefinite(rest, 3, []))
          4 -> decode_array_indefinite(rest, treatment, [])
          5 -> decode_map_indefinite(rest, treatment, treatment.map.newmap.())
        end
      _ ->
        case mt do
          0 -> {val, rest}
          1 -> {-val - 1, rest}
          2 -> treatment.bytes.(decode_string(rest, val))
          3 -> treatment.text.(decode_string(rest, val))
          4 -> decode_array(val, rest, treatment)
          5 -> decode_map(val, rest, treatment)
          6 ->
            {inner, rest} = decode_with_rest(rest, treatment)
            {decode_tag(val, inner, treatment), rest}
          7 -> case bin do
                 << 0xf9, sign::size(1), exp::size(5), mant::size(10),
                    _::binary >> -> {decode_half(sign, exp, mant, treatment), rest}
                 << 0xfa, value::[float, size(32)], _::binary >> -> {value, rest}
                 << 0xfa, sign::size(1), 255::size(8), mant::size(23),
                    _::binary >> -> {treatment.nonfinites.(sign, mant), rest}
                 << 0xfb, value::[float, size(64)], _::binary >> -> {value, rest}
                 << 0xfb, sign::size(1), 2047::size(11), mant::size(52),
                    _::binary >> -> {treatment.nonfinites.(sign, mant), rest}
                 _ -> case val do
                        20 -> {false, rest}
                        21 -> {true, rest}
                        22 -> {nil, rest}
                        _ -> {{CBOR.Tag, :simple, val}, rest}
                      end
               end
        end
    end
  end
  defp decode_half(sign, 31, mant, treatment), do: treatment.nonfinites.(sign, mant)
  defp decode_half(sign, exp, mant, _) do
    << value::[float, size(32)] >> =
      << sign::size(1), exp::size(8), mant::size(10), 0::size(13) >>
    value * 5192296858534827628530496329220096.0 # 2**112 -- difference in bias
  end
  defp decode_tag(3, value, treatment), do: -decode_tag(2, value, treatment) - 1
  defp decode_tag(2, value, _treatment) do
    # is it a byte string?
    bytes = case value do
      {CBOR.Tag, :bytes, bytes} when is_binary(bytes) -> bytes
      bytes when is_binary(bytes) -> bytes #  when deftag == :bytes XXX
    end
    sz = byte_size(bytes)
    <<res::[integer,unsigned,size(sz),unit(8)]>> = bytes
    res
  end
  defp decode_tag(tag, value, treatment) do
    case treatment.tags[tag] do
      nil -> {CBOR.Tag, tag, value}
      fun -> fun.(tag, value, treatment)
    end
  end
  defp decode_string(rest, len) do
    << value::[binary, size(len)], new_rest::binary >> = rest
    {value, new_rest}
  end
  defp decode_string_indefinite(rest, actmt, acc) do
    case decode_header(rest) do
      {7, :indefinite, new_rest} -> {Enum.join(Enum.reverse(acc)), new_rest}
      {^actmt, len, mid_rest} ->
        << value::[binary, size(len)], new_rest::binary >> = mid_rest
        decode_string_indefinite(new_rest, actmt, [value|acc])
    end
  end
  defp decode_array(0, rest, _), do: {[], rest}
  defp decode_array(len, rest, treatment) do
    decode_array1(len, treatment, [], rest)
  end
  defp decode_array1(0, treatment, acc, bin) do
    {Enum.reverse(acc), bin}
  end
  defp decode_array1(len, treatment, acc, bin) do
    {value, bin_rest} = decode_with_rest(bin, treatment)
    decode_array1(len - 1, treatment, [value|acc], bin_rest)
  end
  defp decode_array_indefinite(rest, treatment, acc) do
    case rest do
      << 7::size(3), 31::size(5), new_rest::binary >> ->
        {Enum.reverse(acc), new_rest}
      _ ->
        {value, new_rest} = decode_with_rest(rest, treatment)
        decode_array_indefinite(new_rest, treatment, [value|acc])
    end
  end
  defp decode_map(0, rest, treatment), do: {treatment.map.empty_map.(), rest}
  defp decode_map(len, rest, treatment) do
    decode_map1(len, treatment, treatment.map.newmap.(), rest)
  end
  defp decode_map1(0, treatment, acc, bin) do
    {treatment.map.finish_map.(acc), bin}
  end
  defp decode_map1(len, treatment, acc, bin) do
    {key, bin_rest} = decode_with_rest(bin, treatment)
    {value, bin_rest} = decode_with_rest(bin_rest, treatment)
    decode_map1(len - 1, treatment, treatment.map.add_to_map.(acc, key, value), bin_rest)
  end
  defp decode_map_indefinite(rest, treatment, acc) do
    case rest do
      << 7::size(3), 31::size(5), new_rest::binary >> ->
        {case acc do
           [] -> treatment.map.empty_map.()
           _ -> treatment.map.finish_map.(acc)
         end, new_rest}
      _ ->
        {key, new_rest} = decode_with_rest(rest, treatment)
        {value, new_rest} = decode_with_rest(new_rest, treatment)
        decode_map_indefinite(new_rest, treatment, treatment.map.add_to_map.(acc, key, value))
    end
  end
  # --------------------
  def encode_head(mt, val) when val < 24, do: << mt::size(3), val::size(5) >>
  def encode_head(mt, val) when val < 0x100 do
    << mt::size(3), 24::size(5), val::[unsigned, size(8)] >>
  end
  def encode_head(mt, val) when val < 0x10000 do
    << mt::size(3), 25::size(5), val::[unsigned, size(16)] >>
  end
  def encode_head(mt, val) when val < 0x100000000 do
    << mt::size(3), 26::size(5), val::[unsigned, size(32)] >>
  end
  def encode_head(mt, val) when val < 0x10000000000000000 do
    << mt::size(3), 27::size(5), val::[unsigned, size(64)] >>
  end
  def encode_head_indefinite(mt), do: << mt::size(3), 31::size(5) >>
  def encode_string(mt, s), do: << CBOR.encode_head(mt, byte_size(s)) :: binary, s :: binary >>
  def encode_tag(tag, cb), do: << CBOR.encode_head(6, tag) :: binary, cb :: binary >>
  def encode(v), do: CBOR.Encoder.encode(v)
  defprotocol Encoder do
    def encode(element)
  end
  defimpl Encoder, for: Integer do
    def encode(i) when i >= 0 and i < 0x10000000000000000, do: CBOR.encode_head(0, i)
    def encode(i) when i < 0 and i >= -0x10000000000000000, do: CBOR.encode_head(1, -i-1)
    def encode(i) when i >= 0 , do: encode_as_bignum(i, 2)
    def encode(i) when i < 0 , do: encode_as_bignum(-i-1, 3)
    defp encode_as_bignum(i, tag) do
      s = case :erlang.term_to_binary(i) do
        <<131, 110, _, 0, s::binary>> -> s
        <<131, 111, _, _, _, _, 0, s::binary>> -> s
      end
      s = iolist_to_binary(:lists.reverse(lc <<b>> inbits s do b end))
      CBOR.encode_tag(tag, CBOR.encode_string(2, s))
    end
  end
  defimpl Encoder, for: Float do
    # def encode(x), do: << 0xfb, x::[float, size(64)] >>  # that would be fast
    def encode(x) do
      try1 = << x::[float, size(32)] >> # beware: this may be an infinite
      case try1 do
        << ^x::[float, size(32)] >> -> # infinites are caught here
          case try1 do
            << sign::size(1), 0::size(31) >> -> # +0.0, -0.0
              << 0xf9, sign::size(1), 0::size(15) >>
            << sign::size(1), exp::size(8), mant1::size(10), 0::size(13) >>
            when exp > 112 and exp < 143 -> # don't try to generate denormalized binary16
              << 0xf9, sign::size(1), (exp-112)::size(5), mant1::size(10) >>
            _ -> << 0xfa, try1::binary >>
          end
        _ -> << 0xfb, x::[float, size(64)] >>
      end
    end
  end
  defimpl Encoder, for: Atom do
    def encode(false), do: << 0xf4 >>
    def encode(true), do: << 0xf5 >>
    def encode(nil), do: << 0xf6 >> # XXX : what about other atoms?
  end
  defimpl Encoder, for: BitString do # XXX add treatments?
    def encode(s), do: CBOR.encode_string(3, s)
  end
  defimpl Encoder, for: CBOR.Tag do
    def encode({CBOR.Tag, :bytes, s}), do: CBOR.encode_string(2, s)
    def encode({CBOR.Tag, :float, :inf}), do: << 0xf9, 0x7c, 0 >>
    def encode({CBOR.Tag, :float, :"-inf"}), do: << 0xf9, 0xfc, 0 >>
    def encode({CBOR.Tag, :float, :nan}), do: << 0xf9, 0x7e, 0 >>
    def encode({CBOR.Tag, :simple, val}) when val < 0x100, do: CBOR.encode_head(7, val)
    def encode({CBOR.Tag, tag, val}), do: CBOR.encode_tag(tag, CBOR.Encoder.encode(val))
  end
  defimpl Encoder, for: HashDict do
    def encode(dict) do
      iolist_to_binary([ << CBOR.encode_head(5, Dict.size(dict))::binary >> |
                         (Enum.map(dict, fn({k, v}) ->
                                             << (CBOR.Encoder.encode(k)) :: binary,
                                             (CBOR.Encoder.encode(v)) :: binary >> end))])
    end
  end
  defimpl Encoder, for: List do
    def encode([]), do: << 0x80 >>
    def encode([{}]), do: << 0xa0 >> # treat as map
    def encode(map = [{_,_}|_]) do   # treat as map
      << CBOR.encode_head(5, length(map))::binary,
         bc {key, value} inlist map do
        << (CBOR.Encoder.encode(key)) :: binary, (CBOR.Encoder.encode(value)) :: binary >>
      end :: binary >>
    end
    def encode(list) do
      << CBOR.encode_head(4, length(list))::binary,
              (bc el inlist list, do: << CBOR.Encoder.encode(el) :: binary >>) :: binary >>
    end
  end
  # defimpl Encoder, for: Tuple do      # anything else we can do here?
  # end
end
