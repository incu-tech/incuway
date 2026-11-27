# Specs from Code conventions (incu/specs-from-code)

Applies whenever you write or edit anything under `docs/specs/`.

- **Behavior, not structure.** A spec describes what is observable from outside the component:
  inputs, outputs, errors and side effects. Never name frameworks, annotations, classes or layers.
  External contract names (paths, fields, topics, commands) are behavior and stay.
- **Evidence or a question.** Every business rule cites `path:line`, a config key, or usage data.
  A rule without code evidence is marked **(unverified)** and has a closed question in `QUESTIONS.md`.
- **Nothing invented.** An unknown value is `null` plus a warning (inventory) or a question
  (spec). Usage numbers come only from a provided source.
- **Exact errors.** An error is a condition plus the exact observable result, not a bare status code.
- **No secrets.** Configuration is recorded by name only. Example payloads use synthetic data.
- **Read-only over the component.** The specs flow does not change application code or config.
- **Signed means frozen.** An approved `SPEC.md` is changed only through a refresh run, which
  sends it back to `draft` and requires a new sign-off.
