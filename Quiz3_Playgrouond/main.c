// rv32i_fast_rsqrt.c
#include <stdint.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#define printstr(ptr, length)                   \
    do {                                        \
        asm volatile(                           \
            "add a7, x0, 0x40;"                 \
            "add a0, x0, 0x1;" /* stdout */     \
            "add a1, x0, %0;"                   \
            "mv a2, %1;" /* length character */ \
            "ecall;"                            \
            :                                   \
            : "r"(ptr), "r"(length)             \
            : "a0", "a1", "a2", "a7");          \
    } while (0)

#define TEST_OUTPUT(msg, length) printstr(msg, length)

#define TEST_LOGGER(msg)                     \
    {                                        \
        char _msg[] = msg;                   \
        TEST_OUTPUT(_msg, sizeof(_msg) - 1); \
    }

extern uint64_t get_cycles(void);
extern uint64_t get_instret(void);

/* Bare metal memcpy implementation */
void *memcpy(void *dest, const void *src, size_t n)
{
    uint8_t *d = (uint8_t *) dest;
    const uint8_t *s = (const uint8_t *) src;
    while (n--)
        *d++ = *s++;
    return dest;
}

/* Software division for RV32I (no M extension) */
static unsigned long udiv(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long quotient = 0;
    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (1UL << i);
        }
    }

    return quotient;
}

static unsigned long umod(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
        }
    }

    return remainder;
}

/* Software multiplication for RV32I (no M extension) */
static uint32_t umul(uint32_t a, uint32_t b)
{
    uint32_t result = 0;
    while (b) {
        if (b & 1)
            result += a;
        a <<= 1;
        b >>= 1;
    }
    return result;
}

/* Provide __mulsi3 for GCC */
uint32_t __mulsi3(uint32_t a, uint32_t b)
{
    return umul(a, b);
}

/* --------- 32x32 -> 64 shift-add multiply (no MUL) ------------------------- */
/* Algorithm: for each set bit i in b, add (a << i) into 64-bit accumulator.  */
static uint64_t mul32(uint32_t a, uint32_t b) {
    uint64_t r = 0;
    for (int i = 0; i < 32; ++i) {
        if (b & (1U << i))                 /* C01 */
            r += ((uint64_t)a << i);       /* C02 (be aware of casting) */
    }
    return r;
}

/* Simple integer to hex string conversion */
static void print_hex(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            int digit = val & 0xf;
            *p = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
            p--;
            val >>= 4;
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}

/* Simple integer to decimal string conversion */
static void print_dec(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            *p = '0' + umod(val, 10);
            p--;
            val = udiv(val, 10);
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}


/* Print unsigned decimal without trailing newline (used for inline formatting) */
static void print_uint_no_nl(unsigned long val)
{
    char buf[24];
    int i = 0;
    if (val == 0) {
        buf[i++] = '0';
    } else {
        char tmp[24];
        int ti = 0;
        while (val) {
            tmp[ti++] = '0' + (char)umod(val, 10);
            val = udiv(val, 10);
        }
        for (int k = ti - 1; k >= 0; --k)
            buf[i++] = tmp[k];
    }
    printstr(buf, i);
}

/* Print Q16 fixed-point value y (y/65536) with `frac_digits` fractional digits */
static void print_q16(uint32_t y, unsigned frac_digits)
{
    uint32_t int_part = y >> 16;

    /* multiplier = 10^frac_digits */
    uint64_t mult = 1;
    for (unsigned i = 0; i < frac_digits; ++i)
        mult *= 10ULL;

    /* compute fractional part using 64-bit intermediate and round */
    /* use mul32 to avoid hardware MUL instruction */
    uint64_t frac64 = (mul32((uint32_t)(y & 0xFFFF), (uint32_t)mult) + (1ULL << 15)) >> 16;
    if (frac64 >= mult) {
        /* rounding carried into integer part */
        int_part += 1;
        frac64 = 0;
    }

    print_uint_no_nl(int_part);

    /* decimal point and fractional part with leading zeros */
    char dot = '.';
    printstr(&dot, 1);

    /* prepare fractional digits with leading zeros */
    char fbuf[32];
    int fi = 0;
    if (mult == 0) {
        /* unlikely, but safe guard */
        for (unsigned i = 0; i < frac_digits; ++i)
            fbuf[fi++] = '0';
    } else {
        {
            /* frac64 fits in 32 bits (mult <= 1e9 typically); use udiv/umod */
            unsigned long tmp = (unsigned long)frac64;
            for (int d = frac_digits - 1; d >= 0; --d) {
                fbuf[d] = '0' + (char)umod(tmp, 10);
                tmp = udiv(tmp, 10);
            }
        }
        fi = frac_digits;
    }
    printstr(fbuf, fi);
}

/* --------- clz: count leading zeros (special case x==0 returns 32) --------- */
static int clz(uint32_t x) {
    if (!x) return 32;                 /* Special case: no bits set */
    int n = 0;
    if (!(x & 0xFFFF0000u)) { n += 16; x <<= 16; }
    if (!(x & 0xFF000000u)) { n +=  8; x <<=  8; }
    if (!(x & 0xF0000000u)) { n +=  4; x <<=  4; }
    if (!(x & 0xC0000000u)) { n +=  2; x <<=  2; }
    if (!(x & 0x80000000u)) { n +=  1; }
    return n;
}


/* --------- Lookup table: initial estimates for 65536 / sqrt(2^exp) --------- */
static const uint16_t rsqrt_table[32] = {
    65536, 46341, 32768, 23170, 16384,  /* 2^0  to 2^4  */
    11585,  8192,  5793,  4096,  2896,  /* 2^5  to 2^9  */
     2048,  1448,  1024,   724,   512,  /* 2^10 to 2^14 */
      362,   256,   181,   128,    90,  /* 2^15 to 2^19 */
       64,    45,    32,    23,    16,  /* 2^20 to 2^24 */
       11,     8,     6,     4,     3,  /* 2^25 to 2^29 */
        2,     1                         /* 2^30, 2^31  */
};

/* --------- Fast reciprocal sqrt: returns y = 65536 / sqrt(x) --------------- */
/* Error ~3–8% after LUT + interpolation + 2 Newton iters (Q16 fixed-point).   */
uint32_t fast_rsqrt(uint32_t x) {
    /* Edge cases */
    if (x == 0) return 0xFFFFFFFFu;   /* Infinity representation */
    if (x == 1) return 65536u;        /* Exact */

    /* Step 1: find MSB position */
    int exp = 31 - clz(x);            /* C03 */

    /* Step 2: LUT initial estimate */
    uint32_t y = rsqrt_table[exp];    /* C04 */

    /* Step 3: Linear interpolation for non power of two */
    if (x > (1u << exp)) {
        /* Bound-safe next table entry; exp==31 → use 0 */
        uint32_t y_next = (exp < 31) ? rsqrt_table[exp + 1] : 0;  /* C05 */
        uint32_t delta  = y - y_next;                             /* C06 */
        /* frac = ((x - 2^exp) / 2^exp) in Q16 */
        uint32_t frac   = (uint32_t)(((((uint64_t)x - (1ULL << exp)) << 16) >> exp)); /* C07 */
        /* y -= delta * frac / 2^16 */
        y -= (uint32_t)(mul32(delta,frac) >> 16);          /* C08 */
    }

    /* Step 4: two Newton-Raphson iterations in Q16:
       y_{n+1} = y_n * (3/2 - x*y_n^2/2^16) / 1
       Implemented as: y = (y * ((3<<16) - (x*y^2>>16))) >> 17
    */
    for (int iter = 0; iter < 2; ++iter) {
        uint32_t y2  = (uint32_t)mul32(y, y);                     /* C09 (Q32) */
        uint32_t xy2 = (uint32_t)(mul32(x, y2) >> 16);            /* C10 (Q16) */
        y = (uint32_t)(mul32(y, (3u << 16) - xy2) >> 17);         /* C11 */
    }

    return y;
}

/* ------------------------- 小型測試 ------------------------------ */
int main(void) {
    uint32_t xs[] = {1, 4, 16, 20, 100, 0, 0xFFFFFFFFu};
    for (unsigned i = 0; i < sizeof(xs)/sizeof(xs[0]); ++i) {
        uint32_t x = xs[i];
        TEST_LOGGER("x = ");
        print_dec(x);


        uint32_t y = fast_rsqrt(x);
        TEST_LOGGER("  y = ");
        print_dec(y);
        if (y == 0xFFFFFFFFu) {
            TEST_LOGGER("  (Actual value = infinity)\n");
            continue;
        }
        TEST_LOGGER("  (y/65536 ~= ");
        /* print integer.part and fractional part (6 digits) */
        print_q16(y, 6);
        TEST_LOGGER(")\n");
        
    }
    return 0;
}
