;  core.inc - sparse
;
;  Core language definitions



def define,'['
      mov eax,overide
      mov [status],eax
      call name
      mov ebp,[ddp]
      mov eax,[edi]                 ; get first 4 chars of current word in eax
      mov [ebp+name_offset],eax      ; name new definition

      mov edx,[current]  ; update current definitions
      mov eax,[edx]
      mov [edx],ebp
      mov [ebp+link_offset],eax    ; and link

      mov eax,[cdp]      ; code pointer
      mov [ebp+code_offset],eax
      
      lea ebp,[ebp+data_offset]    ; advance ddp
      mov [ddp],ebp

      mov eax,[macros]        ; switch to macros for compiling
      mov [dictionary],eax
      ret

macro enddef,']'
      mov edx,[context]        ; switch back to context definitions for interpreting
      mov ebx,[edx]
      mov [dictionary],ebx
      ret




