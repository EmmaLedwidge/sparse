;  dictionary.inc - sparse.asm
;
;  macros to construct dictionary headers
; 
; parameters: label defines code space address of routine, for nasm code reference
;             'name' defines the 32bit string constant token


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
  
; For regular dictionary definitions
%define dlink 0              ; last dictionary header in data space
%macro def 2                 ; def label,'name'
  SECTION .data
  %%link  dd %2, dlink, %1
  %define dlink %%link
  SECTION .text
  %1: 
  %define ldef %1             ; last definition code address
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
          mov ebx,ldef
          mov ecx,%%entry-ldef-1    ; ldef code lenth - ret
          jmp doinline
%endmacro

doinline:
        mov ebp,[cdp]
.rep    mov edx,[ebx]
        mov [ebp],edx
        lea ebx,[ebx+4]
        lea ebp,[ebp+4]
        sub ecx,4
        jnle .rep
        add ebp,ecx
        mov [cdp],ebp
        ret


