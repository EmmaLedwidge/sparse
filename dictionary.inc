;  dictionary.inc - sparse.asm
;
;  defines macros to construct headers for the dictionaries,
; and initialise them with their defaults

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
  



; dictionary defaults


lex lex_word,0                ; default 
      mov ebp,[ddp]
      mov eax,[ebp+pad]       ; return first 4 chars of current word in eax
      ret



def not_found,0               ; word not found
      mov edx,[cwc]
      mov ebp,[ddp]
      lea ecx,[ebp+pad]
      mov [ecx+edx],byte '?'
      mov [ecx+edx+1],byte lf
      add edx,2
      jmp report      ; should be quit" or error and reset interpreter


macro compile,0      ; macro not found
      mov edx,[context]
      mov ebx,[edx]
      call find
      mov eax,[ebx+de.link]
      test eax,eax
      jnz ccal
      jmp [ebx+de.code]  ; defer handling to context 

ccal: mov edi,[cdp]              ; compile call
      mov [edi],byte 0xE8        ; call opcode
      inc edi
      mov eax,[ebx+de.code] 
      sub eax,4                     
      sub eax,edi
      stosd
      mov [cdp],edi
      ret


