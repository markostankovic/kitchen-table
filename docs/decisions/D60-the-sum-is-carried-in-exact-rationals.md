## D60 — The sum is carried in exact rationals, and stored as an integer pair

**Decided.** `lib/features/shopping_list/domain/rational.dart` is an exact
rational type; the aggregation converts, scales and sums entirely in it, and
rounds only when rendering. `units.to_base` is read through
`Rational.parseDecimal` from `Unit.toBaseExact` — the `numeric` exactly as
Postgres sent it — not through `Unit.toBase`'s `double`.
`shopping_list_items.quantities` stores `amount_num` / `amount_den`, not
`docs/DATA_MODEL.md`'s sketched single `amount`.

**Why.** Rule 5, and `Quantity`'s own doc comment, which predicted this exact
moment: "A shopping list that sums halves and thirds across a week has to land
on exact numbers or it will quietly ask for 0.9999999 kg of flour." The thing
that makes it affordable is that **no `to_base` value is irrational** —
`28.349523125` is `28349523125 / 10^9` — so exactness costs a parse of a
string that was already on the wire, not a new unit table. `⅓ šolje` three
times is 240 ml, not 239.99998, and the emulator run confirmed the equivalent:
`2 dl` plus `⅓ šolje` summed to exactly 280 ml.

Storing the pair rather than a number keeps that guarantee across the wire. A
rounded column would put a float back in the one place rule 5 was written to
keep it out of, and a list that is regenerated or re-read would round twice.

**Consequence.** `Unit` gains `toBaseExact`, nullable, beside the existing
`toBase`. Two representations of one constant is a smell, but the alternative
was changing `toBase` to a rational and rewriting the parser and line editor,
which do not care about exactness and for which a `double` is the right type
— the field's own doc already said so.

**Rejected.** Summing in `double` and rounding at render — the rounding does
hide most of the drift, which is exactly what makes it a bad trade: the bug
would be invisible until a quantity was wrong in a shop. Making `Quantity` do
the arithmetic — it models what a cook wrote, carries ranges and renders as
`1½`; an intermediate sum is a different thing and does not want a range.
