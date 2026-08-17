# US-001 - Provider global reference inventory

Static audit scope: `work/generated/ghidra/*.cpp`. The requested `0x629Fxx`
labels are not the effective addresses. Every guest instruction below first loads
`0x00620000` and then applies a signed `0x9Fxx` offset, so the effective globals
are `0x00619F40`, `0x00619F41`, `0x00619F44`, `0x00619F4C`, and `0x00619F50`.

## Guest instruction references

| Global | Instruction | Access | Generated file | Evidence |
|---|---:|---|---|---|
| `0x619F40` | `0x4FAAA4` | write byte | `FUN_004faa10_0x4faa10.cpp` | `sb $v0,-0x60C0($a0)` |
| `0x619F40` | `0x4FAA04` | write byte | `FUN_004fa7a8_0x4fa7a8.cpp` | `sb $a0,-0x60C0($v1)` |
| `0x619F40` | `0x4FAEE8` | read byte | `sub_004FAED8_0x4faed8.cpp` | `lbu $v1,-0x60C0($v0)` |
| `0x619F41` | `0x4FAAA0` | write byte | `FUN_004faa10_0x4faa10.cpp` | `sb $v0,-0x60BF($v1)` |
| `0x619F41` | `0x4FA940` | write byte | `FUN_004fa7a8_0x4fa7a8.cpp` | `sb $v1,-0x60BF($v0)` |
| `0x619F41` | `0x4FAEFC` | read byte | `sub_004FAED8_0x4faed8.cpp` | `lbu $v1,-0x60BF($v0)` |
| `0x619F44` | `0x4F9780` | read word | `FUN_004f9760_0x4f9760.cpp` | `lw $a0,-0x60BC($v0)` |
| `0x619F44` | `0x1AF118` | address reference, not a load/store | `FUN_001af0b0_0x1af0b0.cpp` | forms `0x619F44` in `$a2` for the call at `0x1AF114` |
| `0x619F4C` | `0x4F979C` | read word | `FUN_004f9760_0x4f9760.cpp` | `lw $s0,-0x60B4($v0)` |
| `0x619F4C` | `0x4F9808` | read word | `FUN_004f97e8_0x4f97e8.cpp` | `lw $s0,-0x60B4($v0)` |
| `0x619F4C` | `0x4F99F0` | read word | `FUN_004f99c8_0x4f99c8.cpp` | `lw $s0,-0x60B4($v0)` |
| `0x619F4C` | `0x4F9A74` | read word | `sub_004F9A68_0x4f9a68.cpp` | `lw $v1,-0x60B4($a1)` |
| `0x619F4C` | `0x4F9A8C` | write word | `sub_004F9A68_0x4f9a68.cpp` | `sw $a0,-0x60B4($a1)` |
| `0x619F4C` | `0x4F9B14` | write word | `sub_004F9AA0_0x4f9aa0.cpp` | `sw $v0,-0x60B4($v1)` |
| `0x619F4C` | `0x4F9B40` | read word | `sub_004F9B38_0x4f9b38.cpp` | `lw $v0,-0x60B4($v1)` |
| `0x619F4C` | `0x4F9B54` | read word | `sub_004F9B38_0x4f9b38.cpp` | `lw $a0,-0x60B4($s0)` |
| `0x619F4C` | `0x4F9B60` | read word | `sub_004F9B38_0x4f9b38.cpp` | `lw $v0,-0x60B4($s0)` |
| `0x619F4C` | `0x4F9B68` | read word | `sub_004F9B38_0x4f9b38.cpp` | `lw $a0,-0x60B4($s0)` |
| `0x619F50` | `0x4FA430` | read byte | `sub_004FA428_0x4fa428.cpp` | `lbu $v1,-0x60B0($v0)` |
| `0x619F50` | `0x4FA57C` | write byte | `sub_004FA488_0x4fa488.cpp` | `sb $v0,-0x60B0($v1)` |

The combined generated file `sub_004F95F8_0x4f95f8.cpp` repeats guest
instructions `0x4F9780`, `0x4F979C`, `0x4F9808`, and `0x4F99F0`. Likewise,
`sub_004F9980_0x4f9980.cpp` repeats `0x4F99F0`. These are duplicate renderings,
not additional runtime references.

## Host-side diagnostic reads

Existing `MC3_TRACE_PROVIDER` instrumentation also calls `READ8(0x619F40)` in
`FUN_00206638_0x206638.cpp`, `FUN_00447928_0x447928.cpp`,
`FUN_004faa10_0x4faa10.cpp`, `sub_001A0CF0_0x1a0cf0.cpp`,
`sub_001A0DB0_0x1a0db0.cpp`, `sub_001A12D0_0x1a12d0.cpp`,
`sub_00206548_0x206548.cpp`, `sub_00398318_0x398318.cpp`,
`sub_00429FC0_0x429fc0.cpp`, `sub_00447CF8_0x447cf8.cpp`,
`sub_004FA398_0x4fa398.cpp`, and `sub_004FA488_0x4fa488.cpp`. These are
environment-gated host diagnostics, not original guest instructions or
producers. No equivalent diagnostic access exists for the other four globals.

## Conclusions and negative case

- The required example is confirmed at guest `0x4F9760`: instruction
  `0x4F9780` reads primary `0x619F44`, then `0x4F979C` reads fallback
  `0x619F4C`.
- No guest load/store writes `0x619F44` in the generated corpus. The only other
  reference forms its address at `0x1AF118`; producer initialization therefore
  cannot be assigned from this inventory alone.
- Literal text such as instruction address `0x4F9F44` is excluded: it does not
  encode or calculate a reference to either `0x619F44` or the requested
  `0x629F44`.
- Literal opcode words such as `0xAC629F4C` are not treated as absolute
  `0x629F4C`; the signed base-plus-offset calculation is what proves the
  effective `0x619F4C` access.
- No source file was modified for this story; this report is the sole result.

## Reproduction

```powershell
rg -n --glob '*.cpp' '(0x[0-9a-fA-F]{4}(9[fF]40|9[fF]41|9[fF]44|9[fF]4[cC]|9[fF]50)|429494(2528|2529|2532|2540|2544))' work/generated/ghidra
```

The command must exit zero. Review each hit with its preceding `lui`; a
`0x00620000` base plus the signed offsets above resolves to `0x00619Fxx`.
