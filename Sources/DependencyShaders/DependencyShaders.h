#pragma once

#import <simd/simd.h>

#if !defined(__METAL_VERSION__)
typedef simd_float3 float3;
#endif

struct Vertex {
    float3 position;
    float3 color;
};
