#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static unsigned state = 1234;

static unsigned xorshift(void)
{
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    return state;
}

int main(int argc, char **argv)
{
    int usePow = argc > 1 && strcmp(argv[1], "pow") == 0;
    int secs = argc > 2 ? atoi(argv[2]) : 20;
    time_t deadline = time(NULL) + secs;
    volatile double zero = 0.0, one = 1.0;
    unsigned long long iters = 0, powBad = 0, cmpBad = 0;

    while (time(NULL) < deadline)
    {
        for (int k = 0; k < 100000; k++)
        {
            iters++;
            double r = (xorshift() | 1) / 4294967295.0;
            double e = 1.0 / (2 + (iters % 7));
            if (usePow)
            {
                volatile double p1 = pow(r, e);
                volatile double p2 = pow(r, e);
                if (isnan(p1) || isnan(p2) || p1 != p2)
                    powBad++;
            }
            double a = nextafter(zero, INFINITY);
            double b = nextafter(one, -INFINITY);
            if (!(a <= b))
                cmpBad++;
        }
    }
    printf("%s %s: iters=%llu powBad=%llu cmpBad=%llu\n",
#if defined(__aarch64__)
        "arm64",
#else
        "x86_64",
#endif
        usePow ? "pow" : "cmp", iters, powBad, cmpBad);
    return 0;
}
