#include <metal_stdlib>
using namespace metal;

kernel void a(device float *x [[buffer(0)]], uint i [[thread_position_in_grid]]) {
    x[i] *= 2;
}
#if defined(CONFIG_DEBUG)
kernel void configurationDebug() {}
#elif defined(CONFIG_RELEASE)
kernel void configurationRelease() {}
#endif
