; utility subroutine for clamping a 8.8 fixed-point value
clamp_fixed_point:
    ; Compare value with min_value
    lda value_high
    cmp min_value_high
    bmi @set_to_min      ; if it was a minus result, i.e. the value_high < min_value_high: set to minimum value
    beq @check_min_low   ; If high octets are equal, just check low for min

@check_for_max:
    ; Compare value with max_value
    lda value_high
    cmp max_value_high
    beq @check_max_low   ; If high octets are equal, check low byte for maximum
    bpl @set_to_max      ; it it was a positve result, i.e. value_high > max_value_high: set to maximum

    ; If value_high is between min_value_high and max_value_high, it is within range
    rts

@check_min_low:
    ; High octets are equal, compare low octets for minimum
    lda value_low
    cmp min_value_low
    bmi @set_to_min      ; If value_low < min_value_low, set to minimum
    ; If low byte is greater than or equal to min_value_low, continue to max check
    jmp @check_for_max ; we have only handled minimum values, so jump to the check for max after this

@check_max_low:
    ; High octets are equal, compare low octets for maximum
    lda value_low
    cmp max_value_low
    bpl @set_to_max      ; If value_low > max_value_low, set to maximum

    ; If within range, return
    rts

@set_to_min:
    ; Set value to minimum
    lda min_value_high
    sta value_high
    lda min_value_low
    sta value_low
    rts

@set_to_max:
    ; Set value to maximum
    lda max_value_high
    sta value_high
    lda max_value_low
    sta value_low
    rts
