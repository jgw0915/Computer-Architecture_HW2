#include <stdint.h>


extern uint32_t clz(uint32_t x);
extern uint64_t mul32(uint32_t a, uint32_t b);

/* --------- Lookup table: initial estimates for 65536 / sqrt(2^exp) --------- */
static const uint32_t rsqrt_table[32] = {
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