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

/* ============= uf8_decode Declaration ============= */

extern int32_t uf8_decode(uint8_t uf8);

/* ============= uf8_decode Declaration ============= */

extern uint8_t uf8_encode(int32_t value);

/* Test encode/decode round-trip */
static bool test(void)
{
    int32_t previous_value = -1;
    bool passed = true;
    uint64_t start_cycles, end_cycles, cycles_elapsed;
    uint64_t start_instret, end_instret, instret_elapsed;

    TEST_LOGGER("=== UF8 Encode/Decode Round-Trip Test ===\n\n");
    for (int i = 0; i < 256; i++) {
        uint8_t fl = i;

        start_cycles = get_cycles();
        start_instret = get_instret();

        int32_t value = uf8_decode(fl);
        uint8_t fl2 = uf8_encode(value);

        end_cycles = get_cycles();
        end_instret = get_instret();
        cycles_elapsed = end_cycles - start_cycles;
        instret_elapsed = end_instret - start_instret;

        if (fl != fl2) {
            TEST_LOGGER("Re-encode Test Failed: \n");
            print_hex((unsigned long)fl);
            TEST_LOGGER(": produce value ");
            print_dec((unsigned long)value);
            TEST_LOGGER(", but re-encoded back to ");
            print_hex((unsigned long)fl2);
            TEST_LOGGER("\n");
            passed = false;
        }

        if (value <= previous_value) {
            TEST_LOGGER("Previous value Test Failed :\n");
            print_hex((unsigned long)fl);
            TEST_LOGGER(": value ");
            print_dec((unsigned long)value);
            TEST_LOGGER(" <= previous value ");
            print_dec((unsigned long)previous_value);
            TEST_LOGGER("\n");
            passed = false;
        }

        if (passed){
            TEST_LOGGER("uf8: 0x");
            print_hex((unsigned long)fl);
            TEST_LOGGER("Decoded value: ");
            print_dec((unsigned long)value);
            TEST_LOGGER("Re-encoded uf8: 0x");
            print_hex((unsigned long)fl2);
            TEST_LOGGER("Cycles (decode/encode): ");
            print_dec((unsigned long) cycles_elapsed);
            TEST_LOGGER("Instructions (decode/encode): ");
            print_dec((unsigned long) instret_elapsed);

            TEST_LOGGER("\n");
        }

        previous_value = value;
    }

    return passed;
}

int main(void)
{
    TEST_LOGGER("=== Test Start ===\n");
    if (test()) {
        TEST_LOGGER("=== All tests passed ===\n");
        return 0;
    }else{
        TEST_LOGGER("=== Some tests failed ===\n");
    }
    return 1;
}
