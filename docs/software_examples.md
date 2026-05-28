```
.globl main

/* Program to toggle on-board LED every second */

main:
    /* Load address of T0L in t0 */
    la    t0, __t0l
    /* Prescale set to 1000 */
    li    a0, 1000
    sw    a0, 0(t0)

    /* Load address of T0H in t0 */
    la    t0, __t0h
    /* Match value set to 63999 */
    li    a0, 63999
    sw    a0, 0(t0)

    /* Set Timer A */
    la    t0, __t0con
    lw    a0, 0(t0)
    or    a0, a0, (1 << 2)
    sw    a0, 0(t0)

    /* LED = 0x1 */
    la    t0, __gpio_led
    li    a0, 1
    sw    a0, 0(t0)

toggle:
    /* Toggle LED */
    la    t0, __gpio_led
    lw    a0, 0(t0)
    xori  a0, a0, 1
    sw    a0, 0(t0)
    call  delay
    j     toggle

delay:
    la    t0, __t0con
    la    t1, __tfreg

    /* Start Timer A */
    lw    a0, 0(t0)
    or    a0, a0, (1 << 0)
    sw    a0, 0(t0)

wait:
    lw    a0, 0(t1)
    and   a0, a0, 1
    /* wait till TFREG.T0AF == 1 */
    beqz  a0, wait
exit_delay:
    /* Stop Timer A */
    lw    a0, 0(t0)
    and   a0, a0, ~(1 << 0)
    sw    a0, 0(t0)

    /* Set T0CON.T0ACLRF */
    lw    a0, 0(t0)
    or    a0, a0, (1 << 4)
    sw    a0, 0(t0)

    ret
```