; utility subroutine for clamping a 8.8 fixed-point value
clamp_fixed_point:
    ; Compare value with min_value
    lda value_high
    sec
    sbc min_value_high
    bcc set_to_min      ; If value_high < min_value_high, set to minimum
    beq check_low_min   ; If high bytes are equal, check low byte for minimum

    ; Compare value with max_value
    lda value_high
    sec
    sbc max_value_high
    bcs set_to_max      ; If value_high > max_value_high, set to maximum
    beq check_low_max   ; If high bytes are equal, check low byte for maximum

    ; If value_high is between min_value_high and max_value_high, it is within range
    rts

check_low_min:
    ; High bytes are equal, compare low bytes for minimum
    lda value_low
    cmp min_value_low
    bcc set_to_min      ; If value_low < min_value_low, set to minimum
    ; If low byte is greater than or equal to min_value_low, continue to max check
    bne check_low_max   ; If not equal, it means value is above min_value

check_low_max:
    ; High bytes are equal, compare low bytes for maximum
    lda value_low
    cmp max_value_low
    bcs set_to_max      ; If value_low > max_value_low, set to maximum

    ; If within range, return
    rts

set_to_min:
    ; Set value to minimum
    lda min_value_high
    sta value_high
    lda min_value_low
    sta value_low
    rts

set_to_max:
    ; Set value to maximum
    lda max_value_high
    sta value_high
    lda max_value_low
    sta value_low
    rts
