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
ok:   db "ok",lf
okc:  equ $-ok
lc:   db 0

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


name: xor eax,eax      ; read one word from input
      mov ebp,[ddp]
      mov [ebp+pad_offset],eax
      mov [cwc],eax

skip: call getc         ; skip leading spaces and ctrl chars
      cmp al,ws
      jle skip

scan: mov ecx,[cwc]     ; copy printable chars into current word buffer
      mov [ebp+ecx+pad_offset],al
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
      mov ebp,[ddp]
      mov [ebp+pad_offset],eax     ; reset cw
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


