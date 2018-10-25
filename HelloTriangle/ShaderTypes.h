//
//  ShaderTypes.h
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
//  Created by WebQA on 10/16/18.
//  Copyright © 2018 WebQA. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match Metal API buffer set calls
typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
    VertexInputIndexViewportSize = 1,
} VertexInputIndex;

/// Vertex Structure
typedef struct
{
    // Positions in pixel space
    // (e.g. a value of 100 indicates 100 pixels from the center)
    vector_float2 position;
    
    // Floating-point RGBA colors
    vector_float4 color;
} Vertex;

#endif /* ShaderTypes_h */

