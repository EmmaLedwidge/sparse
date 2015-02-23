;  core.inc - sparse
;
;  Core language definitions



def define,'['
      mov eax,overide
      mov [status],eax
      call name
      mov ebp,[ddp]
      mov eax,[edi]                 ; get first 4 chars of current word in eax
      mov [ebp+de.name],eax      ; name new definition

      mov edx,[current]  ; update current definitions
      mov eax,[edx]
      mov [edx],ebp
      mov [ebp+de.link],eax    ; and link

      mov eax,[cdp]      ; code pointer
      mov [ebp+de.code],eax
      
      lea ebp,[ebp+de.data]    ; advance ddp
      mov [ddp],ebp

      mov eax,[macros]        ; switch to macros for compiling
      mov [dictionary],eax
      ret

macro enddef,']'
      mov edx,[context]        ; switch back to context definitions for interpreting
      mov ebx,[edx]
      mov [dictionary],ebx
      ret



macro return,';'
      mov ebx,[cdp]
      mov [ebx],byte 0xC3           ; ret opcode
      inc ebx
      mov [cdp],ebx
      ret


def dup,'dup'
      _dup
      ret
;inline 'dup'


def drop,'drop'
      _drop
      ret
;inline 'drop'


