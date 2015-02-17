;  sparse.asm
;
; assemble:   nasm -f elf -l sparse.lst sparse.asm
; link:       ld -s -o sparse  sparse.o
; run:        ./sparse

%define std_in 0
%define std_out 1
%define sys_exit 1
%define sys_read 3
%define sys_write 4
%define ws 32
%define lf 10

%define name_offset 0
%define link_offset 4
%define code_offset 8
%define data_offset 12


; Header macros 
; parameters: label defines code space address of routine, for nasm code reference
;             'name' defines the 32bit string constant token for Sparse code reference

; For regular dictionary definitions
%define dlink 0              ; last dictionary header in data space
%macro def 2                 ; def label,'name'
  SECTION .data
  %%link  dd %2, dlink, %1
  %define dlink %%link
  SECTION .text
  %1: 
  %define ldef $            ; last definition code address
%endmacro

; For stand alone macro definitions
%define mlink 0               ; last macro header in data space
%macro macro 2                ; macro label,'name'
  SECTION .data
  %%link  dd %2, mlink, %1
  %define mlink %%link
  SECTION .text
  %1:
%endmacro

; For inlining dictionary definitions when compiling. use directly following regular definition.
%macro inline 1               ; inline 'name'
  SECTION .data
  %%link  dd %1, mlink, %%entry
  %define mlink %%link
  SECTION .text
  %%entry:
          mov esi,ldef
          mov ecx,%%entry-ldef-1    ; ldef code lenth - ret
          jmp doinline
%endmacro

; Lexical recognition entry
;  lexical evaluation iterates over each lex entry until one returns its token. The iteration
;  is hard coded, and the header entries are included only for reference.
%define llink 0               ; last lex header
%macro lex 2                  ; lex label, 'name' 
  SECTION .data
  %%link  dd %2, llink, %1
  %define llink %%link
  SECTION .text
  %1:
%endmacro
  


      SECTION .data
msg:  db "SPF testbed",lf
msgc:  equ $-msg
ok:   db "ok",lf
okc:  equ $-ok
lc:   db 0

cdp:  dd cspace
ddp:  dd dspace

      SECTION .bss
cwc:  resd 1          ; current word count and buffer
cwb:  resb 10
cspace: resb 100
dspace: resb 100

      SECTION .text
      global _start


getc: xor eax,eax      ; read one char from (blocking) input buffer
      push eax
      mov edx,1
      mov ecx,esp
      mov ebx,eax      ; 0, stdin
      mov eax,sys_read
      int 0x80         ; nb error if less than 1?
      pop eax          ; return in al
      ret


name: xor eax,eax      ; read one word from input
      mov [cwb],eax
      mov [cwc],eax

skip: call getc         ; skip leading spaces and ctrl chars
      cmp al,ws
      jle skip

scan: mov ecx,[cwc]     ; copy printable chars into current word buffer
      mov [cwb+ecx],al
      inc ecx
      mov [cwc],ecx
      call getc
      cmp al,ws
      jnle scan

      mov [lc],al        ; save eolf at end of line for interpreter
      ret


find: cmp [ebx+link_offset],dword 0     ;execute default entry
      jz found
      cmp eax,[ebx+name_offset]   ; or matched entry
      jz found
      mov ebx,[ebx+link_offset]
      jmp find
found: 
      ret




_start:
      mov edx,msgc
      mov ecx,msg
      jmp report

status:
      mov edx,okc      ; type 'ok'
      mov ecx,ok
report:
      mov ebx,std_out
      mov eax,sys_write
      int 0x80

interpret:
      xor eax,eax
      mov [cwb],eax     ; reset cw
      mov [cwc],eax
.skip:              ; based on word except we break at eol to report status ok
      call getc
      cmp al,lf
      jz status
      cmp al,ws
      jle .skip
      call scan

      mov ebx,[lexers]            ; evaluate / get token
      call [ebx+code_offset]   ; eax = token
      mov ebx,[dictionary]         ; search macros or context dictionary
      call find
      call [ebx+code_offset]   ; execute

      mov al,[lc]     ; test for saved eol
      cmp al,lf
      jnz interpret
      jmp status



; dictionary defaults


lex lex_word,0                    ; default 
      mov eax,[cwb]      ; return first 4 chars of current word in eax
      ret



def not_found,0          ; word not found
      mov edx,[cwc]
      mov ecx,cwb
      mov [ecx+edx],byte '?'
      mov [ecx+edx+1],byte lf
      add edx,2
      jmp report      ; should be quit" or error and reset interpreter


macro compile,0      ; macro not found
      mov edx,[context]
      mov ebx,[edx]
      call find
      mov eax,[ebx+link_offset]
      test eax,eax
      jnz ccal
      jmp [ebx+code_offset]  ; defer handling to context 

ccal: mov edi,[cdp]              ; compile call
      mov [edi],byte 0xE8        ; call opcode
      inc edi
      mov eax,[ebx+code_offset] 
      sub eax,4                     
      sub eax,edi
      stosd
      mov [cdp],edi
      ret

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


; definitions


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


def quit,'quit'
      mov ebx,0
      mov eax,sys_exit
      int 0x80


      SECTION .data
definitions: dd dlink
macros: dd mlink
lexers: dd llink
current: dd definitions
context: dd definitions
dictionary: dd dlink   

; dictionary - macros or context interpreter state, controls compilation
; context    - which definitions to interpret, or compile
; current    - where to compile definitions, typicaly set to context


