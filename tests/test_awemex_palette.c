#include "../DYYYAwemeXPalette.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>

static void close_to(double actual, double expected) {
    assert(fabs(actual - expected) < 1e-14);
}

int main(void) {
    for (uint32_t i = 0; i < 128; ++i) {
        close_to(DYYYAwemeXDanmakuChannel(i), (128.0 + i) / 255.0);
    }
    close_to(DYYYAwemeXDanmakuChannel(0), 128.0 / 255.0);
    close_to(DYYYAwemeXDanmakuChannel(127), 1.0);
    close_to(DYYYAwemeXGradientHue(255), 255.0 / 256.0);
    close_to(DYYYAwemeXGradientHue(256), 0.0);
    close_to(DYYYAwemeXGradientSaturation(127), 0.99609375);
    close_to(DYYYAwemeXGradientSaturation(128), 0.5);
    close_to(DYYYAwemeXGradientBrightness(101), 0.99453125);
    close_to(DYYYAwemeXGradientBrightness(102), 0.6);
    assert(DYYYAwemeXGradientStopCount(0) == 2);
    assert(DYYYAwemeXGradientStopCount(1) == 3);

    uint32_t value = 0x12345678u;
    for (unsigned i = 0; i < 100000; ++i) {
        value ^= value << 13; value ^= value >> 17; value ^= value << 5;
        double h = DYYYAwemeXGradientHue(value);
        double s = DYYYAwemeXGradientSaturation(value);
        double b = DYYYAwemeXGradientBrightness(value);
        assert(h >= 0.0 && h <= 0.99609375);
        assert(s >= 0.5 && s <= 0.99609375);
        assert(b >= 0.6 && b <= 0.99453125);
        uint32_t quotient = (uint32_t)(((uint64_t)value * 0xa0a0a0a1u) >> 38);
        close_to(b, 0.6 + (value - quotient * 102u) / 256.0);
    }
    puts("AwemeX palette: endpoints, all 128 RGB levels, stop counts and 100000 HSB samples passed.");
    return 0;
}
