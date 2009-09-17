#include        asm86.h
#include        ti86asm.inc
#include        ti86abs.inc

        .org    _asm_exec_ram
start:
        call    _clrLCD
        ld      hl,0000h
        ld      (_curRow),hl
        ld      (_penCol),hl

        ld      hl,progvar-1
        rst     20h
        rst     10h
        ld      a,b
        ex      de,hl
        call    _load_ram_ahl
        inc     hl
        inc     hl
        inc     hl
        inc     hl

        ld      (progp),hl

;        ld      (progp),b
;        ld      (progp+1),de
main:
        call    _getky
        cp      K_EXIT
        jr      z,keyquit

;        ld      a,(progp)
;        ld      hl,(progp+1)
;        call    _GETB_AHL
;        call    _inc_ptr_ahl

        ld      hl,(progp)
        ld      a,(hl)
        inc     hl

        cp      forth_end
        jp      z,f_end

        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
;        ld      (progp),a
;        ld      (progp+1),hl
        ld      (progp),hl

        push    de
        sla     a
        ld      l,a
        ld      h,00h
        ld      de,cmds
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        pop     de
        jp      (hl)

        jr      main

f_end:
        pop     hl
keyquit:
        xor     a
        ld      (_curCol),a
        ld      a,6
        ld      (_curRow),a
        ret

;**********************************************************
pop_de:
        ex      de,hl
        call    pop_hl
        ex      de,hl
        ret

;**********************************************************
pop_hl:
        ld      hl,(stackp)
        dec     hl
        ld      a,(hl)
        dec     hl
        ld      (stackp),hl
        ld      l,(hl)
        ld      h,a
        ret

;**********************************************************
; hl - number to push
push_hl:
        ex      de,hl
        call    push_de
        ex      de,hl
        ret

;**********************************************************
; de - number to push
push_de:
f_num:
        push    hl
        ld      hl,(stackp)
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (stackp),hl
        pop     hl
        ret

;**********************************************************
; de - length of string
f_str:
        ret

;**********************************************************
; de - something
f_flt:
        ret

;**********************************************************
; de - variable number
f_var:
        ld      hl,vars
        add     hl,de
        add     hl,de
        call    push_hl
        ret

;**********************************************************
; de - word number
f_wrd:
        ld      h,d
        ld      l,e
        add     hl,de
        ld      de,dict
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        jp      (hl)

;**********************************************************
; de      - address
; (stack) - condition
f_if:
f_while:
        call    pop_hl

        ld      a,h
        or      l
        jr      z,wif_skip
        ret

wif_skip:
        ld      de,(progp)
        add     hl,de
        ld      (progp),hl
        ret

;**********************************************************
; de - address
f_else:
f_goto:
f_repeat:
        ld      hl,(progp)
        add     hl,de
        ld      (progp),hl
        ret

;**********************************************************
; de      - address
; (stack) - condition
f_until:
        call    pop_hl

        ld      a,h
        or      l
        jr      nz,wu_done

        ld      hl,(progp)
        scf
        ccf
        sbc     hl,de
        ld      (progp),hl
wu_done:
        ret

;**********************************************************
; de - address
f_call:
        push    de
        ld      de,(progp)
        ld      hl,(rstackp)
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (rstackp),hl
        pop     de

        ld      hl,(progp)
        add     hl,de
        ld      (progp),hl
        ret

;**********************************************************
f_ret:
        ld      hl,(rstackp)
        dec     hl
        ld      a,(hl)
        dec     hl
        ld      (rstackp),hl
        ld      l,(hl)
        ld      h,a
        ld      (progp),hl
        ret

;**********************************************************
word_add:
        call    pop_de
        call    pop_hl
        add     hl,de
        call    push_hl
        ret

;**********************************************************
word_sub:
        call    pop_de
        call    pop_hl
;        ld      a,l
;        sub     e
;        ld      l,a
;        ld      a,h
;        sbc     a,d
;        ld      h,a

        scf
        ccf
        sbc     hl,de

        call    push_hl
        ret

;**********************************************************
; In:
;       DE - Multiplicand, Unsigned
;       B - Multiplier, Unsigned
; Out:
;       HL - Product
;       DE - Destroyed
;       B - 0
mul16:
        ld      hl,0000h
mul16_loop:
        srl     b
        jr      nc,mul16_cont
        add     hl,de
mul16_cont:
        ret     z
        ex      de,hl
        add     hl,hl
        ex      de,hl
        jp      mul16_loop

;**********************************************************
word_mul:
        call    pop_hl
        call    pop_de
        ld      b,l

        call    mul16

        call    push_hl
        ret

;**********************************************************
; In:
;       HL - Dividend
;       D - Divisor
; Out:
;       IX - Quotient
;       H - Remainder
;       L - Destroyed
;       D - Unchanged
;       E - 0
;       A - Destroyed
div16:
        ld      a,l
        ld      l,h
        ld      h,00h
        ld      e,00h
        ld      b,16
        ld      ix,0
div16_loop:
        add     hl,hl
        rla
        jp      nc,div16_loop1
        inc     l
div16_loop1:
        add     ix,ix
        inc     ix
        or      a
        sbc     hl,de
        jp      nc,div16_cont
        add     hl,de
        dec     ix
div16_cont:
        djnz    div16_loop

        ret


;**********************************************************
word_div:
        call    pop_de
        call    pop_hl
        ld      d,e
        call    div16
        push    ix
        pop     hl
        call    push_hl
        ret

;**********************************************************
word_mod:
        call    pop_de
        call    pop_hl
        ld      d,e
        call    div16
        ld      l,h
        ld      h,00h
        call    push_hl
        ret        

;**********************************************************
word_xor:
        call    pop_de
        call    pop_hl
        ld      a,l
        xor     e
        ld      l,a
        ld      a,h
        xor     d
        ld      h,a
        call    push_hl
        ret

;**********************************************************
word_and:
        call    pop_de
        call    pop_hl
        ld      a,l
        and     e
        ld      l,a
        ld      a,h
        and     d
        ld      h,a
        call    push_hl
        ret

;**********************************************************
word_or:
        call    pop_de
        call    pop_hl
        ld      a,l
        or      e
        ld      l,a
        ld      a,h
        or      d
        ld      h,a
        call    push_hl
        ret

;**********************************************************
word_not:
        call    pop_hl
        ld      a,l
        xor     0ffh
        ld      l,a
        ld      a,h
        xor     0ffh
        ld      h,a
        call    push_hl
        ret

;**********************************************************
word_eq0:
        call    pop_hl
        ld      a,l
        or      h
        jr      z,weq0_zero
        ld      de,0000h
        call    push_de
        ret

weq0_zero:
        ld      de,0ffffh
        call    push_de
        ret

;**********************************************************
word_print:
        call    pop_de
        ld      a,d
        call    printbyte
        ld      a,e
        call    printbyte
        ret

;**********************************************************
word_cr:
        xor     a
        ld      (_curCol),a
        ld      a,(_curRow)
        cp      7
        jr      z,wcr_scroll
        inc     a
        ld      (_curRow),a
        ret

wcr_scroll:
        ld      hl,VIDEO_MEM
        ld      de,16*8+VIDEO_MEM
        ld      b,3
wcr_1:
        ld      c,0
wcr_2:
        ld      a,(de)
        inc     de
        ld      (hl),a
        inc     hl
        dec     c
        jr      nz,wcr_2
        dec     b
        jr      nz,wcr_1

        ld      c,128
wcr_3:
        ld      a,(de)
        inc     de
        ld      (hl),a
        inc     hl
        dec     c
        jr      nz,wcr_3

        ld      c,128
        xor     a
wcr_4:
        ld      (hl),a
        inc     hl
        djnz    wcr_4
        ret

;**********************************************************
word_readword:
        call    pop_hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        call    push_de
        ret

;**********************************************************
word_readbyte:
        call    pop_hl
        ld      e,(hl)
        ld      d,00h
        call    push_de
        ret

;**********************************************************
word_writeword:
        call    pop_hl
        call    pop_de
        ld      (hl),e
        inc     hl
        ld      (hl),d
        ret

;**********************************************************
word_writebyte:
        call    pop_hl
        call    pop_de
        ld      (hl),e
        ret

;**********************************************************
word_dup:
        call    pop_hl
        call    push_hl
        call    push_hl
        ret

;**********************************************************
word_swap:
        call    pop_hl
        call    pop_de
        call    push_hl
        call    push_de
        ret

;**********************************************************
word_drop:
        call    pop_hl
        ret

;**********************************************************
word_emit:
        call    pop_hl
        ld      a,l
        call    _putc
        ret

;**********************************************************
word_gt:
        call    pop_hl
        call    pop_de
        ld      a,h
        cp      d
        jr      z,wgt_same
        jr      c,wgt_less
wgt_more:
        ld      de,0000h
        call    push_de
        ret

wgt_same:
        ld      a,l
        cp      e
        jr      z,wgt_more
        jr      c,wgt_less
        jr      wgt_more

wgt_less:
        ld      de,0ffffh
        call    push_de
        ret


;**********************************************************
word_lt:
        call    pop_hl
        call    pop_de
        ld      a,h
        cp      d
        jr      z,wlt_same
        jr      nc,wlt_more
wlt_less:
        ld      de,0000h
        call    push_de
        ret

wlt_same:
        ld      a,l
        cp      e
        jr      z,wlt_less
        jr      nc,wlt_more
        jr      wlt_less

wlt_more:
        ld      de,0ffffh
        call    push_de
        ret

;**********************************************************
word_key:
        call    _getkey
        ld      h,00h
        ld      l,a
        call    push_hl
        ret

;**********************************************************
word_getkey:
        call    _getky
        ld      h,00h
        ld      l,a
        call    push_hl
        ret

;**********************************************************
word_space:
        ld      a,(_curCol)
        inc     a
        ld      (_curCol),a
        ret

;**********************************************************
word_spaces:
        call    pop_hl
        ld      a,(_curCol)
        add     a,l
        ld      (_curCol),a
        ret

;**********************************************************
word_2dup:
        call    pop_hl
        call    pop_de
        call    push_de
        call    push_hl
        call    push_de
        call    push_hl
        ret

;**********************************************************
word_equal:
        call    pop_hl
        call    pop_de
        ld      a,h
        cp      d
        jr      nz,we_notequal
        ld      a,l
        cp      e
        jr      nz,we_notequal
        ld      de,0ffffh
        call    push_de
        ret

we_notequal:
        ld      de,0000h
        call    push_de
        ret

;**********************************************************
word_lshift:
        call    pop_de
        call    pop_hl
wls_shift:
        ld      a,h
        sla     a
        sla     l
        adc     a,0
        ld      h,l
        dec     e
        jr      nz,wls_shift
        ret

;**********************************************************
word_rshift:
        call    pop_de
        call    pop_hl
wrs_shift:
        srl     l
        srl     h
        jr      nc,wrs_noadd
        ld      a,%10000000
        add     a,h
        ld      h,a
wrs_noadd:
        dec     e
        jr      nz,wls_shift
        ret

;**********************************************************
word_nip:
        call    pop_de
        call    pop_hl
        call    push_de
        ret

;**********************************************************
word_tuck:
        call    pop_de
        call    pop_hl
        call    push_de
        call    push_hl
        call    push_de
        ret

;**********************************************************
word_rot:
        call    pop_hl
        call    pop_de
        ld      (tempw),hl
        call    pop_hl
        call    push_de
        ld      d,h
        ld      e,l
        ld      hl,(tempw)
        call    push_hl
        call    push_de
        ret

;**********************************************************
word_printbyte:
        call    pop_de
        ld      a,e
        call    printbyte
        ret

;**********************************************************
word_1plus:
        call    pop_hl
        inc     hl
        call    push_hl
        ret

;**********************************************************
word_1minus:
        call    pop_hl
        dec     hl
        call    push_hl
        ret

;**********************************************************
word_2plus:
        call    pop_hl
        inc     hl
        inc     hl
        call    push_hl
        ret

;**********************************************************
word_2minus:
        call    pop_hl
        dec     hl
        dec     hl
        call    push_hl
        ret

;**********************************************************
word_2mult:
        call    pop_hl
        ld      a,h
        sla     a
        sla     l
        adc     a,0
        ld      h,l
        call    push_hl
        ret

;**********************************************************
word_2div:
        call    pop_hl
        srl     l
        srl     h
        jr      nc,w2d_noadd
        ld      a,%10000000
        add     a,h
        ld      h,a
w2d_noadd:
        call    push_hl
        ret

;**********************************************************
word_cls:
        call    _clrLCD
        ld      hl,0000h
        ld      (_curRow),hl
        ld      (_penCol),hl
        ret

;**********************************************************
printbyte:
        push    af
        sra     a
        sra     a
        sra     a
        sra     a
        and     $0f
        add     a,$30
        cp      $3a
        jp      c,pb1
        add     a,7 
pb1:    ;ld      (tempnum),a
        call    _putc
        pop     af
        push    af
        and     $0f
        add     a,$30
        cp      $3a
        jp      c,pb2
        add     a,7
pb2:    ;ld      (tempnum+1),a
        ;push    hl
        ;ld      hl,tempnum
        ;call    _puts
        ;pop     hl
        call    _putc
        pop     af
        ret

;**********************************************************

tempw   .dw     0000h
;tempnum .db     0,0,0

progvar .db     5,"fprog",0
progp   ;.db     00h
        .dw     0000h
;varp    .dw     vars
rstackp .dw     rstack
stackp  .dw     stack

        ; Commands
cmds    .dw     f_end           ;  0 - forth_end
        .dw     f_num           ;  1 - forth_number
        .dw     f_str           ;  2 - forth_string
        .dw     f_flt           ;  3 - forth_float
        .dw     f_var           ;  4 - forth_variable
        .dw     f_wrd           ;  5 - forth_word
        .dw     f_if            ;  6 - forth_if/forth_while
        .dw     f_else          ;  7 - forth_else/forth_goto/forth_repeat
        .dw     f_until         ;  8 - forth_until
        .dw     f_call          ;  9 - forth_call
        .dw     f_ret           ; 10 - forth_ret

        ; a few quits just incase
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end

        ; CORE
dict    .dw     word_writeword  ;  0 - !    - store
        .dw     word_mul        ;  1 - *    - star
        .dw     word_add        ;  2 - +    - plus
        .dw     word_sub        ;  3 - -    - minus
        .dw     word_print      ;  4 - .    - dot
        .dw     word_div        ;  5 - /    - slash
        .dw     word_eq0        ;  6 - 0=   - zero-equals
        .dw     word_2dup       ;  7 - 2dup - two-dupe
        .dw     word_lt         ;  8 - <    - less-than
        .dw     word_equal      ;  9 - =    - equals
        .dw     word_gt         ;  a - >    - greater-than
        .dw     word_readword   ;  b - @    - fetch
        .dw     word_and        ;  c - and
        .dw     word_writebyte  ;  d - C!   - c-store
        .dw     word_readbyte   ;  e - C@   - c-fetch
        .dw     word_cr         ;  f - cr   - c-r
        .dw     word_drop       ; 10 - drop
        .dw     word_dup        ; 11 - dup  - dupe
        .dw     word_emit       ; 12 - emit
        .dw     0               ; 13
        .dw     0               ; 14
        .dw     word_not        ; 15 - invert
        .dw     word_key        ; 16 - key
        .dw     word_mod        ; 17 - mod
        .dw     word_or         ; 18 - or
        .dw     0               ; 19
        .dw     word_space      ; 1a - space
        .dw     word_spaces     ; 1b - spaces
        .dw     word_swap       ; 1c - swap
        .dw     word_lshift     ; 1d - lshift
        .dw     word_rshift     ; 1e - rshift
        .dw     0               ; 1f
        .dw     word_xor        ; 20 - xor  - x-or
        .dw     word_getkey     ; 21
        .dw     word_nip        ; 22 - nip
        .dw     word_tuck       ; 23 - tuck
        .dw     word_rot        ; 24 - rot
        .dw     0               ; 25
        .dw     0               ; 26
        .dw     word_printbyte  ; 27 - .b
        .dw     word_1plus      ; 28 - 1+
        .dw     word_1minus     ; 29 - 1-
        .dw     word_2plus      ; 2a - 2+
        .dw     word_2minus     ; 2b - 2-
        .dw     word_2mult      ; 2c - 2*
        .dw     word_2div       ; 2d - 2/
        .dw     word_cls        ; 2e - cls

        ; a few quits just incase
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end
        .dw     f_end

forth_end       = 0
forth_number    = 1     ; number:word
forth_string    = 2     ; length:word, string:bytes[length]
forth_float     = 3     ; number:float
forth_variable  = 4     ; variablenum:word
forth_word      = 5     ; word:word
forth_if        = 6     ; addr:word
forth_while     = forth_if
forth_else      = 7     ; addr:word
forth_goto      = forth_else
forth_repeat    = forth_else
forth_until     = 8     ; addr:word
forth_call      = 9     ; addr:word
forth_ret       = 10    ; 0:word

endp:
vars    equ     endp            ; 128 words
rstack  equ     vars+(128*2)    ; 16 words
stack   equ     rstack+(16*2)

;       variables
;       stack

        .end
