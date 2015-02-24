;  output.inc - sparse
;


; numeric output

def dot,'.'              ; < n -- > out:string 
      xor edx,edx        ; digit
      mov ebp,[ddp]
      lea ecx,[ebp+pad]  ; string addr
.digit:
      dec ecx
      mov dl,al          ; n,lsbits
      and dl,7
      or dl,'0'
      mov [ecx],dl
      shr eax,3          ; next digit
      jnz .digit
      lea edx,[ebp+pad]  ; string count
      sub edx,ecx
      mov ebx,std_out
      mov eax,sys_write
      int 0x80

      xor eax,eax        ; supress status
      mov [status],eax
      _drop
      ret

