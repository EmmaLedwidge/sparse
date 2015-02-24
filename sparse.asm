;  sparse.asm
;
; assemble:   nasm -f elf -l sparse.lst sparse.asm
; link:       ld -s -o sparse  sparse.o
; run:        ./sparse

%include 'sysdefs.inc'
%include 'dictionary.inc'
%include 'defaults.inc' 

      SECTION .data
msg:  db "SPF testbed",lf
msgc:  equ $-msg
ok:   dd okc
okt:  db "ok",lf
okc  equ $-okt
overide: dd 4
         db "... "

status: dd ok
lc:   db lf

cdp:  dd cspace
ddp:  dd dspace

      SECTION .bss
cwc:  resd 1          ; current word count and buffer
cspace: resb 100
dspace: resb 1000     ; include space for pad at +100

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


def name,'word'                  ; ( -- n ; M=addr )
      _dup
      xor eax,eax                ; zero word buffer
      mov ebp,[ddp]
      mov [ebp+pad],eax
      mov [cwc],eax
.entry:
      mov al,[lc]
      cmp al,lf
      jz .stat
      jmp .sop
.stat:
      mov edi,[status]           ; string constant
      test edi,edi
      jz .restat
      mov edx,[edi]              ; len
      lea ecx,[edi+4]
      mov ebx,std_out
      mov eax,sys_write
      int 0x80
.restat:
      mov edi,ok
      mov [status],edi
.sol:                            ; start of line
      call getc
      cmp al,ws
      jle .sol                   ; suppressing status (DRY)
      jmp .sot
.sop:                            ; start of parse
      call getc                  ; skip leading spaces and ctrl chars
      cmp al,lf
      jz .stat
      cmp al,ws
      jle .sop
.sot:                            ; start of text
      mov ecx,[cwc]              ; append char
      mov [ebp+ecx+pad],al
      inc ecx
      mov [cwc],ecx
      call getc
      cmp al,ws
      jnle .sot
.eot:                            ; end of text
      mov [lc],al                ; save last char 
      mov edi,ok                 ; restore from overide
      mov [status],edi
      lea edi,[ebp+pad]          ; M:addr
      mov eax,ecx                ; len
      ret


find: cmp [ebx+de.link],dword 0     ;execute default entry
      jz found
      cmp eax,[ebx+de.name]   ; or matched entry
      jz found
      mov ebx,[ebx+de.link]
      jmp find
found: 
      _drop
      ret




_start:
      lea esi,[esp-100]       ; init data stack
      mov edx,msgc            ; startup message
      mov ecx,msg
report:
      mov ebx,std_out
      mov eax,sys_write
      int 0x80
      
      xor eax,eax              ; supress status
      mov [status],eax
interpret:
      call name
      mov ebx,[lexers]         ; evaluate / get token
      call [ebx+de.code]       ; eax = token
      mov ebx,[dictionary]     ; search macros or context dictionary
      call find
      call [ebx+de.code]       ; execute
      jmp interpret


def bye,'bye'
      mov ebx,0
      mov eax,sys_exit
      int 0x80

def define,'['
      mov edx,overide
      mov [status],edx
      call name
      mov eax,[edi]              ; get first 4 chars of current word in eax
      mov ebp,[ddp]
      mov [ebp+de.name],eax      ; name new definition

      mov edx,[current]          ; update current definitions
      mov eax,[edx]
      mov [edx],ebp
      mov [ebp+de.link],eax      ; and link

      mov eax,[cdp]              ; code pointer
      mov [ebp+de.code],eax
      
      lea ebp,[ebp+de.data]      ; advance ddp
      mov [ddp],ebp

      mov eax,[macros]           ; switch to macros for compiling
      mov [dictionary],eax
      _drop
      ret

macro enddef,']'
      mov edx,[context]        ; switch back to context definitions for interpreting
      mov ebx,[edx]
      mov [dictionary],ebx
      ret



      %include 'output.inc'
      %include 'core.inc'


; tie up dictionary chains

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


