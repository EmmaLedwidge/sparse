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


; WIP preparing to properly define KEY
key:  ;_dup
      xor eax,eax      ; read one char from (blocking) input buffer
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
      lea edi,[ebp+pad]          ; edi = $addr
      mov [edi],eax
      mov [cwc],eax
.entry:
      mov al,[lc]
      cmp al,lf
      jz .stat
      jmp .sop
.stat:
      mov ebp,[status]           ; load string constant addr
      test ebp,ebp
      jz .restat
      mov edx,[ebp]              ; len
      lea ecx,[ebp+4]            ; string addr
      mov ebx,std_out
      mov eax,sys_write
      int 0x80
.restat:
      mov ebp,ok
      mov [status],ebp
.sol:                            ; start of line
      call key
      cmp al,ws
      jle .sol                   ; suppressing status if no text entered
      jmp .sot
.sop:                            ; start of parse
      call key                   ; skip leading spaces and ctrl chars
      cmp al,lf
      jz .stat
      cmp al,ws
      jle .sop
.sot:                            ; start of text
      mov ebp,edi                
.nc:  stosb                      ; append char
      call key
      cmp al,ws
      jnle .nc
.eot:                            ; end of text
      mov [lc],al                ; save last char (ws|lf)
      mov eax,edi
      sub eax,ebp                ; count
      mov [cwc],eax
      mov edi,ebp                ; M:caddr
      mov ebp,ok                 ; restore from overide
      mov [status],ebp
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


