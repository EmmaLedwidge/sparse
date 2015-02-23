;  sysdefs - sparse

; OS system calls and constants

%define std_in 0
%define std_out 1

%define sys_exit 1
%define sys_read 3
%define sys_write 4


; useful constants

%define ws 32
%define lf 10


; header fields

%define de.name 0
%define de.link 4
%define de.code 8
%define de.data 12

; scratch pad - offset from ddp

%define pad 100    




; register allocations
;
; eax - top of stack         esp - return stack pointer
; ecx                        ebp - scratch pointer
; edx                        esi - pointer to rest of data stack
; ebx                        edi - M address register

; primary stack operators
 
%macro _dup 0
      lea esi,[esi-4]
      mov [esi],eax
%endmacro

%macro _drop 0
      lodsd
%endmacro

%macro _nip 0
      lea esi,[esi+4]
%endmacro


