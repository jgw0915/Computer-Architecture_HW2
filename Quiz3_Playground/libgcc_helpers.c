/* Minimal implementations of libgcc helpers used on RV32 targets
 * Provide __ashldi3 (left shift 64-bit) and __lshrdi3 (logical right shift 64-bit)
 * Implemented with 32-bit operations to avoid emitting hardware 64-bit shift
 * helpers on RV32 (no M extension).
 */
#include <stdint.h>

unsigned long long __ashldi3(unsigned long long a, int shift)
{
    if ((unsigned)shift >= 64U)
        return 0ULL;
    if (shift == 0)
        return a;

    union {
        unsigned long long v;
        uint32_t w[2]; /* w[0] = low, w[1] = high */
    } u;
    u.v = a;

    uint32_t low = u.w[0];
    uint32_t high = u.w[1];
    uint32_t new_low = 0, new_high = 0;

    if (shift >= 32) {
        unsigned s = (unsigned)shift - 32U;
        if (s < 32)
            new_high = low << s;
        else
            new_high = 0;
        new_low = 0;
    } else {
        unsigned s = (unsigned)shift;
        new_low = low << s;
        new_high = (high << s) | (low >> (32 - s));
    }

    u.w[0] = new_low;
    u.w[1] = new_high;
    return u.v;
}

unsigned long long __lshrdi3(unsigned long long a, int shift)
{
    if ((unsigned)shift >= 64U)
        return 0ULL;
    if (shift == 0)
        return a;

    union {
        unsigned long long v;
        uint32_t w[2]; /* w[0] = low, w[1] = high */
    } u;
    u.v = a;

    uint32_t low = u.w[0];
    uint32_t high = u.w[1];
    uint32_t new_low = 0, new_high = 0;

    if (shift >= 32) {
        unsigned s = (unsigned)shift - 32U;
        if (s < 32)
            new_low = high >> s;
        else
            new_low = 0;
        new_high = 0;
    } else {
        unsigned s = (unsigned)shift;
        new_low = (low >> s) | (high << (32 - s));
        new_high = high >> s;
    }

    u.w[0] = new_low;
    u.w[1] = new_high;
    return u.v;
}
