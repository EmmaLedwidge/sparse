;  core.inc - sparse
;
;  Core language definitions


macro return,';'
      mov ebx,[cdp]
      mov [ebx],byte 0xC3           ; ret opcode
      inc ebx
      mov [cdp],ebx
      ret


def dup,'dup'
      _dup
      ret
inline 'dup'


def drop,'drop'
      _drop
      ret
inline 'drop'


