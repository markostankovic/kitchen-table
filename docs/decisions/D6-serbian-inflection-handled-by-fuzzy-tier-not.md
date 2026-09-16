## D6 — Serbian inflection handled by fuzzy tier, not by morphology

**Decided.** No stemmer. Trigram similarity threshold (start at 0.4) absorbs
*jaje/jaja/jajeta*, *šargarepa/šargarepe*, *brašno/brašna*. Curated core
ingredients get common inflected forms added as explicit aliases.

**Why.** Serbian morphology is heavy but a real stemmer is a research project.
Trigrams plus explicit aliases for the ~200 things that appear constantly is
the 90% solution. Revisit if match quality is bad in practice.
