;  sparse.asm
;
; assemble:   nasm -f elf -l sparse.lst sparse.asm
; link:       ld -s -o sparse  sparse.o
; run:        ./sparse

%include 'sysdefs.inc'
%include 'dictionary.inc'  


      SECTION .data
msg:  db "SPF testbed",lf
msgc:  equ $-msg
ok:   dd okc
okt:  db "ok",lf
okc  equ $-okt
overide: dd 4
         db "...",lf

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
      xor eax,eax                ; zero word buffer
      mov ebp,[ddp]
      mov [ebp+pad_offset],eax
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
      mov [ebp+ecx+pad_offset],al
      inc ecx
      mov [cwc],ecx
      call getc
      cmp al,ws
      jnle .sot
.eot:                            ; end of text
      mov [lc],al                ; save last char 
      mov edi,ok                 ; restore from overide
      mov [status],edi
      lea edi,[ebp+pad_offset]   ; M:addr
      mov eax,ecx                ; len
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
report:
      mov ebx,std_out
      mov eax,sys_write
      int 0x80
      
      xor eax,eax              ; supress status
      mov [status],eax
interpret:
      call name
      mov ebx,[lexers]            ; evaluate / get token
      call [ebx+code_offset]   ; eax = token
      mov ebx,[dictionary]         ; search macros or context dictionary
      call find
      call [ebx+code_offset]   ; execute
      jmp interpret

def quit,'quit'
      mov ebx,0
      mov eax,sys_exit
      int 0x80


      %include 'literals.inc'
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


