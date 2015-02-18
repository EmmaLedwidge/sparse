;  literals.inc - sparse
;



; numeric input - literals

lex lex_lit,'lit'
      mov esi,cwb
      mov ecx,[cwc]
.digit:
      lodsb
      or al,7
      cmp al,0x37
      jnz lex_word
      dec ecx
      jnz .digit
      mov eax,'lit'
      ret


def lit,'lit'
      ;dup
      xor edx,edx
      mov esi,cwb
      mov ecx,[cwc]
.digit:
      lodsb
      and al,7
      shl edx,3
      or dl,al
      dec ecx
      jnz .digit
      mov eax,edx   ; result
      ret


macro dolit,'lit'
       mov edi,[cdp]
                         ; dup,
       mov al,0xB8       ; mov eax,n
       stosb
       call lit
       stosd
       mov [cdp],edi
       ret


