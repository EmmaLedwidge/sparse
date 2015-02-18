;  core.inc - sparse
;
;  Core language definitions



def define,'['
      call name
      mov eax,[cwb]      ; return first 4 chars of current word in eax
      mov ebx,[ddp]      ; compile definition header
      mov [ebx+name_offset],eax      ; name new definition

      mov edx,[current]  ; update current definitions
      mov eax,[edx]
      mov [edx],ebx
      mov [ebx+link_offset],eax    ; and link

      mov eax,[cdp]      ; code pointer
      mov [ebx+code_offset],eax
      
      add ebx,data_offset
      mov [ddp],ebx

      mov eax,[macros]        ; switch to macros for compiling
      mov [dictionary],eax
      ret

macro enddef,']'
      mov edx,[context]        ; switch back to context definitions for interpreting
      mov ebx,[edx]
      mov [dictionary],ebx
      ret




