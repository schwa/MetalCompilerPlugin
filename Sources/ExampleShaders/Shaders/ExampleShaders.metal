#if defined(METAL)

#include "ExampleShaders.h"
#include "DependencyShaders.h"

kernel void k(device float *a [[buffer(0)]], uint i [[thread_position_in_grid]]) {
    a[i] *= 2;
}
#if defined(METAL_COMPILER_PLUGIN_CONFIGURATION_DEBUG)
kernel void configurationDebug() {
}
#elif defined(METAL_COMPILER_PLUGIN_CONFIGURATION_RELEASE)
kernel void configurationRelease() {
}
#else
#error Missing Metal compiler plugin configuration
#endif

#endif
