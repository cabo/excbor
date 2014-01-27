defmodule(CBORTest) do
  use(ExUnit.Case, async: true)
  def(d(bin)) do
    res = CBOR.decode(bin)
    assert(CBOR.decode_with_rest(<<bin :: binary, 47, 11>>) == {res, <<47, 11>>})
    res
  end
  test("fixnum 1") do
    assert(d(CBOR.encode(1)) == 1)
  end
  test("too much data") do
    assert(CBOR.decode_with_rest(CBOR.encode(1) <> "foo") == {1, "foo"})
  end
  test("too little data") do
    assert_raise(FunctionClauseError, fn -> d("") == 1 end)
  end
  test("tag treatment") do
    tag1treat = fn _, v, _ -> {:time, v} end
    treatment = CBOR.Decoder.Treatment[tags: [{1, tag1treat}]]
    assert(CBOR.decode(CBOR.encode({CBOR.Tag, 1, 1390794964}), treatment) == {:time, 1390794964})
    unknowntag = {CBOR.Tag, 4711, 1390794964}
    assert(CBOR.decode(CBOR.encode(unknowntag), treatment) == unknowntag)
  end
  test("RFC 7049 Appendix A Example 1") do
    encoded = <<0>>
    assert(d(encoded) == 0)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 2") do
    encoded = <<1>>
    assert(d(encoded) == 1)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 3") do
    encoded = "\n"
    assert(d(encoded) == 10)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 4") do
    encoded = <<23>>
    assert(d(encoded) == 23)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 5") do
    encoded = <<24, 24>>
    assert(d(encoded) == 24)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 6") do
    encoded = <<24, 25>>
    assert(d(encoded) == 25)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 7") do
    encoded = <<24, 100>>
    assert(d(encoded) == 100)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 8") do
    encoded = <<25, 3, 232>>
    assert(d(encoded) == 1000)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 9") do
    encoded = <<26, 0, 15, 66, 64>>
    assert(d(encoded) == 1000000)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 10") do
    encoded = <<27, 0, 0, 0, 232, 212, 165, 16, 0>>
    assert(d(encoded) == 1000000000000)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 11") do
    encoded = <<27, 255, 255, 255, 255, 255, 255, 255, 255>>
    assert(d(encoded) == 18446744073709551615)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 12") do
    encoded = <<194, 73, 1, 0, 0, 0, 0, 0, 0, 0, 0>>
    assert(d(encoded) == 18446744073709551616)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 13") do
    encoded = <<59, 255, 255, 255, 255, 255, 255, 255, 255>>
    assert(d(encoded) == -18446744073709551616)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 14") do
    encoded = <<195, 73, 1, 0, 0, 0, 0, 0, 0, 0, 0>>
    assert(d(encoded) == -18446744073709551617)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 15") do
    encoded = " "
    assert(d(encoded) == -1)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 16") do
    encoded = ")"
    assert(d(encoded) == -10)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 17") do
    encoded = "8c"
    assert(d(encoded) == -100)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 18") do
    encoded = <<57, 3, 231>>
    assert(d(encoded) == -1000)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 19") do
    encoded = <<249, 0, 0>>
    assert(d(encoded) == 0.0)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 20") do
    encoded = <<249, 128, 0>>
    assert(d(encoded) == 0.0)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 21") do
    encoded = <<249, 60, 0>>
    assert(d(encoded) == 1.0)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 22") do
    encoded = <<251, 63, 241, 153, 153, 153, 153, 153, 154>>
    assert(d(encoded) == 1.1)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 23") do
    encoded = <<249, 62, 0>>
    assert(d(encoded) == 1.5)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 24") do
    encoded = <<249, 123, 255>>
    assert(d(encoded) == 65504.0)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 25") do
    encoded = <<250, 71, 195, 80, 0>>
    assert(d(encoded) == 1.0e5)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 26") do
    encoded = <<250, 127, 127, 255, 255>>
    assert(d(encoded) == 3.4028234663852886e38)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 27") do
    encoded = <<251, 126, 55, 228, 60, 136, 0, 117, 156>>
    assert(d(encoded) == 1.0e300)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 28") do
    encoded = <<249, 0, 1>>
    assert(d(encoded) == 5.960464477539063e-8)
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 29") do
    encoded = <<249, 4, 0>>
    assert(d(encoded) == 6.103515625e-5)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 30") do
    encoded = <<249, 196, 0>>
    assert(d(encoded) == -4.0)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 31") do
    encoded = <<251, 192, 16, 102, 102, 102, 102, 102, 102>>
    assert(d(encoded) == -4.1)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 32") do
    encoded = <<249, 124, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :inf})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 33") do
    encoded = <<249, 126, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :nan})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 34") do
    encoded = <<249, 252, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :"-inf"})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 35") do
    encoded = <<250, 127, 128, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :inf})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 36") do
    encoded = <<250, 127, 192, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :nan})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 37") do
    encoded = <<250, 255, 128, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :"-inf"})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 38") do
    encoded = <<251, 127, 240, 0, 0, 0, 0, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :inf})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 39") do
    encoded = <<251, 127, 248, 0, 0, 0, 0, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :nan})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 40") do
    encoded = <<251, 255, 240, 0, 0, 0, 0, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, :float, :"-inf"})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 41") do
    encoded = <<244>>
    assert(d(encoded) == false)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 42") do
    encoded = <<245>>
    assert(d(encoded) == true)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 43") do
    encoded = <<246>>
    assert(d(encoded) == nil)
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 44") do
    encoded = <<247>>
    assert(d(encoded) == {CBOR.Tag, :simple, 23})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 45") do
    encoded = <<240>>
    assert(d(encoded) == {CBOR.Tag, :simple, 16})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 46") do
    encoded = <<248, 24>>
    assert(d(encoded) == {CBOR.Tag, :simple, 24})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 47") do
    encoded = <<248, 255>>
    assert(d(encoded) == {CBOR.Tag, :simple, 255})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 48") do
    encoded = <<192, 116, 50, 48, 49, 51, 45, 48, 51, 45, 50, 49, 84, 50, 48, 58, 48, 52, 58, 48, 48, 90>>
    assert(d(encoded) == {CBOR.Tag, 0, "2013-03-21T20:04:00Z"})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 49") do
    encoded = <<193, 26, 81, 75, 103, 176>>
    assert(d(encoded) == {CBOR.Tag, 1, 1363896240})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 50") do
    encoded = <<193, 251, 65, 212, 82, 217, 236, 32, 0, 0>>
    assert(d(encoded) == {CBOR.Tag, 1, 1363896240.5})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 51") do
    encoded = <<215, 68, 1, 2, 3, 4>>
    assert(d(encoded) == {CBOR.Tag, 23, {CBOR.Tag, :bytes, <<1, 2, 3, 4>>}})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 52") do
    encoded = <<216, 24, 69, 100, 73, 69, 84, 70>>
    assert(d(encoded) == {CBOR.Tag, 24, {CBOR.Tag, :bytes, "dIETF"}})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 53") do
    encoded = <<216, 32, 118, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 101, 120, 97, 109, 112, 108, 101, 46, 99, 111, 109>>
    assert(d(encoded) == {CBOR.Tag, 32, "http://www.example.com"})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 54") do
    encoded = "@"
    assert(d(encoded) == {CBOR.Tag, :bytes, ""})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 55") do
    encoded = <<68, 1, 2, 3, 4>>
    assert(d(encoded) == {CBOR.Tag, :bytes, <<1, 2, 3, 4>>})
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 56") do
    encoded = "`"
    assert(d(encoded) == "")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 57") do
    encoded = "aa"
    assert(d(encoded) == "a")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 58") do
    encoded = "dIETF"
    assert(d(encoded) == "IETF")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 59") do
    encoded = "b\"\\"
    assert(d(encoded) == "\"\\")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 60") do
    encoded = "bü"
    assert(d(encoded) == "ü")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 61") do
    encoded = "c水"
    assert(d(encoded) == "水")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 62") do
    encoded = "d𐅑"
    assert(d(encoded) == "𐅑")
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 63") do
    encoded = <<128>>
    assert(d(encoded) == [])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 64") do
    encoded = <<131, 1, 2, 3>>
    assert(d(encoded) == [1, 2, 3])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 65") do
    encoded = <<131, 1, 130, 2, 3, 130, 4, 5>>
    assert(d(encoded) == [1, [2, 3], [4, 5]])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 66") do
    encoded = <<152, 25, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 24, 24, 25>>
    assert(d(encoded) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 67") do
    encoded = <<160>>
    assert(d(encoded) == [{}])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 68") do
    encoded = <<162, 1, 2, 3, 4>>
    assert(d(encoded) == [{1, 2}, {3, 4}])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 69") do
    encoded = <<162, 97, 97, 1, 97, 98, 130, 2, 3>>
    assert(d(encoded) == [{"a", 1}, {"b", [2, 3]}])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 70") do
    encoded = <<130, 97, 97, 161, 97, 98, 97, 99>>
    assert(d(encoded) == ["a", [{"b", "c"}]])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 71") do
    encoded = <<165, 97, 97, 97, 65, 97, 98, 97, 66, 97, 99, 97, 67, 97, 100, 97, 68, 97, 101, 97, 69>>
    assert(d(encoded) == [{"a", "A"}, {"b", "B"}, {"c", "C"}, {"d", "D"}, {"e", "E"}])
    assert(CBOR.encode(d(encoded)) == encoded)
  end
  test("RFC 7049 Appendix A Example 72") do
    encoded = <<95, 66, 1, 2, 67, 3, 4, 5, 255>>
    assert(d(encoded) == {CBOR.Tag, :bytes, <<1, 2, 3, 4, 5>>})
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 73") do
    encoded = <<127, 101, 115, 116, 114, 101, 97, 100, 109, 105, 110, 103, 255>>
    assert(d(encoded) == "streaming")
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 74") do
    encoded = <<159, 255>>
    assert(d(encoded) == [])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 75") do
    encoded = <<159, 1, 130, 2, 3, 159, 4, 5, 255, 255>>
    assert(d(encoded) == [1, [2, 3], [4, 5]])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 76") do
    encoded = <<159, 1, 130, 2, 3, 130, 4, 5, 255>>
    assert(d(encoded) == [1, [2, 3], [4, 5]])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 77") do
    encoded = <<131, 1, 130, 2, 3, 159, 4, 5, 255>>
    assert(d(encoded) == [1, [2, 3], [4, 5]])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 78") do
    encoded = <<131, 1, 159, 2, 3, 255, 130, 4, 5>>
    assert(d(encoded) == [1, [2, 3], [4, 5]])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 79") do
    encoded = <<159, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 24, 24, 25, 255>>
    assert(d(encoded) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 80") do
    encoded = <<191, 97, 97, 1, 97, 98, 159, 2, 3, 255, 255>>
    assert(d(encoded) == [{"a", 1}, {"b", [2, 3]}])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 81") do
    encoded = <<130, 97, 97, 191, 97, 98, 97, 99, 255>>
    assert(d(encoded) == ["a", [{"b", "c"}]])
    # (no roundtrip)
  end
  test("RFC 7049 Appendix A Example 82") do
    encoded = <<191, 99, 70, 117, 110, 245, 99, 65, 109, 116, 33, 255>>
    assert(d(encoded) == [{"Fun", true}, {"Amt", -2}])
    # (no roundtrip)
  end
end
