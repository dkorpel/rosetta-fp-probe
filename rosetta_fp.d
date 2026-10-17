import core.stdc.stdio;
import core.stdc.stdlib : atoi;
import core.stdc.math : cpow = pow;
import core.time : MonoTime, seconds;
import std.math.exponential : pow;
import std.math.operations : nextafter;
import std.math.traits : isNaN;

version (Gshared) __gshared uint state = 1234;
else uint state = 1234;

uint xorshift()
{
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    return state;
}

int main(string[] args)
{
    const mode = args.length > 1 ? args[1] : "x87";
    const secs = args.length > 2 ? atoi(args[2].ptr) : 20;
    const deadline = MonoTime.currTime + secs.seconds;

    ulong iters, powMismatch, powNaN, sseBad;
    while (MonoTime.currTime < deadline)
    {
        foreach (_; 0 .. 100_000)
        {
            iters++;
            double r = (xorshift() | 1) / cast(double) uint.max;
            double e = 1.0 / (2 + (iters % 7));

            if (mode != "sse")
            {
                double p1, p2;
                if (mode == "x87")
                {
                    p1 = r ^^ e;
                    p2 = pow(r, e);
                }
                else
                {
                    p1 = cpow(r, e);
                    p2 = cpow(r, e);
                }
                if (p1.isNaN || p2.isNaN)
                    powNaN++;
                else if (*cast(ulong*) &p1 != *cast(ulong*) &p2)
                    powMismatch++;
            }

            double a = nextafter(0.0, double.infinity);
            double b = nextafter(1.0, -double.infinity);
            if (!(a <= b) || a.isNaN || b.isNaN)
                sseBad++;
        }
    }
    printf("%.*s: iters=%llu powNaN=%llu powMismatch=%llu sseBad=%llu\n",
        cast(int) mode.length, mode.ptr, iters, powNaN, powMismatch, sseBad);
    return (powNaN | powMismatch | sseBad) != 0;
}
