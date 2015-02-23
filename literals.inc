;  literals.inc - sparse
;



; numeric input - literals

lex lex_lit,'lit'
      mov ebp,[ddp]
      lea esi,[ebp+pad]
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


def dot,'.'              ; / n -- ; out:string /
      xor edx,edx        ; digit
      mov ebp,[ddp]
      lea ecx,[ebp+pad]  ; string addr
.digit:
      dec ecx
      mov dl,al          ; n,lsbits
      and dl,7
      or dl,'0'
      mov [ecx],dl
      shr eax,3          ; next digit
      jnz .digit
      lea edx,[ebp+pad]  ; string count
      sub edx,ecx
      mov ebx,std_out
      mov eax,sys_write
      int 0x80
      ; drop
      ret

