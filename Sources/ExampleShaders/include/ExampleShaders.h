// This file intentionally left blank.
kernel void k(device float *a [[buffer(0)]], uint i [[thread_position_in_grid]]) {
    a[i] *= 2;
}
