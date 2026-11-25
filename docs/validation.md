# Development-preview validation

## Automated checks

- Native ARM64 application and command-line model tool build successfully.
- Synthetic engine tests cover phrase decoding, bigram scoring, editing bounds, missing dictionaries, manual phrase addition, candidate preference persistence, multiple input contexts, and long compositions.
- AddressSanitizer and UndefinedBehaviorSanitizer engine runs pass.
- The bundled public model contains 172,953 unigram rows (including control records), with no static bigrams.
- Model smoke checks produce `你好` and `今天天氣很好` from Bopomofo readings.
- Source attribution, excluded assets, whitespace, links and public-text privacy checks pass.

## Application integration

A development build passed a manual TextEdit smoke test for standard Bopomofo composition and committing `你好` in an editable document. Automatic UI event injection has not provided reliable coverage and is not counted as an end-to-end pass. The broader application and legacy key-event matrix remains pending.

The app registers and starts as an independent input method. It is ad-hoc signed, not Developer ID signed or notarized. No historical personal dictionary is imported automatically. This evidence supports a development preview, not a production-readiness claim.
