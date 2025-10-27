#if defined(METAL)

#include "ExampleShaders.h"
#include "DependencyShaders.h"

kernel void k(device float *a [[buffer(0)]], uint i [[thread_position_in_grid]]) {
    a[i] *= 2;
}

#endif
