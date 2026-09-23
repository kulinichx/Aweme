#ifndef DYYYAwemeXPalette_h
#define DYYYAwemeXPalette_h

#include <stdint.h>

// Reconstructed numeric rules from the user-supplied AwemeX 2.6.2 sample.
// Keep independent of UIKit so endpoint/range tests exercise the shipped math.
static inline double DYYYAwemeXDanmakuChannel(uint32_t uniform128) {
    return (128u + uniform128) / 255.0;
}

static inline double DYYYAwemeXGradientHue(uint32_t randomValue) {
    return (randomValue & 255u) / 256.0;
}

static inline double DYYYAwemeXGradientSaturation(uint32_t randomValue) {
    return 0.5 + (randomValue & 127u) / 256.0;
}

static inline double DYYYAwemeXGradientBrightness(uint32_t randomValue) {
    return 0.6 + (randomValue % 102u) / 256.0;
}

static inline uint32_t DYYYAwemeXGradientStopCount(uint32_t uniform2) {
    return uniform2 + 2u;
}

#endif
