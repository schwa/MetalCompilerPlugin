#include <metal_stdlib>
using namespace metal;

kernel void b(device float *x [[buffer(0)]], uint i [[thread_position_in_grid]]) {
    x[i] += 1;
}
