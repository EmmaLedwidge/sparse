;  literals.inc - sparse
;



; numeric input - literals

lex lex_lit,'lit'
      mov ebp,[ddp]
      lea ebx,[ebp+pad]
      mov ecx,[cwc]
.digit:
      mov al,[ebx]
      inc ebx
      or al,7
      cmp al,0x37
      jnz lex_word
      dec ecx
      jnz .digit
      mov eax,'lit'
      ret


def lit,'lit'
      _dup
      push esi
      xor edx,edx
      mov ebp,[ddp]
      lea esi,[ebp+pad]
      mov ecx,[cwc]
.digit:
      lodsb
      and al,7
      shl edx,3
      or dl,al
      dec ecx
      jnz .digit
      mov eax,edx   ; result
      pop esi
      ret


macro dolit,'lit'
       mov edi,[cdp]
       mov al,0xB8       ; mov eax,n
       stosb
       call lit
       stosd
       mov [cdp],edi
       _drop
       ret


