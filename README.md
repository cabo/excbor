# ExCBOR

Implementation of RFC 7049 [CBOR](http://cbor.io) (Concise Binary
Object Representation) for Elixir.

## Examples

```elixir
iex(1)> a = CBOR.encode([1, [2, 3]])
<<130, 1, 130, 2, 3>>
iex(2)> CBOR.decode(a)
[1, [2, 3]]
iex(3)> CBOR.decode_with_rest(a <> a)
{[1, [2, 3]], <<130, 1, 130, 2, 3>>}
```

## Caveats

The API is simple enough, but some feedback is encouraged.

This needs at least elixir 0.12.3-dev because of [bug 2012](https://github.com/elixir-lang/elixir/pull/2012).
