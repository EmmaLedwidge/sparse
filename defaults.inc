;  defaults.inc - sparse.asm


; dictionary default behaviours and literals

; LEXERS

lex lex_word,0
      mov ebp,[ddp]
      mov eax,[ebp+pad]       ; return first 4 chars of current word in eax
      ret

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



; DEFINITIONS

def not_found,0               ; word not found
      mov edx,[cwc]
      mov ebp,[ddp]
      lea ecx,[ebp+pad]
      mov [ecx+edx],byte '?'
      mov [ecx+edx+1],byte lf
      add edx,2
      jmp report      ; should be quit" or error and reset interpreter

def lit,'lit'           ; < -- n >
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


; MACRO DEFS

macro compile,0                 ; macro not found
      mov edx,[context]
      mov ebx,[edx]
      call lex_word             ; fix token because find clobered eax
      call find
      mov edx,[ebx+de.link]
      test edx,edx
      jnz .ccall
      jmp [ebx+de.code]          ; defer handling to context default 
.ccall:
      mov ebp,[cdp]              ; or compile call
      mov [ebp],byte 0xE8        ; call 
      lea ebp,[ebp+5]
      mov [cdp],ebp
      mov edx,[ebx+de.code]
      sub edx,ebp
      mov [ebp-4],edx
      ret

macro dolit,'lit'                ; compile literal < -- >
       call lit
       mov ebp,[cdp]
       mov [ebp],dword   0x89FC768D   ; lea esi,[esi-4]; mov
       mov [ebp+4],word  0xB806       ; [esi],eax; mov eax,n
       mov [ebp+6],eax
       lea ebp,[ebp+10]
       mov [cdp],ebp
       _drop
       ret


