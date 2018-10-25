//
//  Renderer.m
//  Implementation of platform independent renderer class, which initializes Metal setup and per-frame Metal commands.
//
//  Created by WebQA on 10/16/18.
//  Copyright © 2018 WebQA. All rights reserved.
//

#import <simd/simd.h>

#import "Renderer.h"

// Include header shared between C code here, which executes Metal API commands and .metal files.
#import "ShaderTypes.h"

// Main class performing the rendering.
@implementation Renderer
{
    // The device (aka GPU) we are using to render.
    id <MTLDevice> _device;

    // The Command Queue is the first object all apps need to interact with the GPU,
    // to create and organize Command Buffer object, ensuring that they’re sent to
    // the GPU in the correct order.
    id <MTLCommandQueue> _commandQueue;

    // The Metal Graphics Rendering Pipeline composed of our vertex and fragment shaders in the .metal shader file.
    id <MTLRenderPipelineState> _pipelineState;

    // The current size of our view. we can use this in our render pipeline.
    vector_uint2 _viewportSize;
    
    // GPU buffer which will contain our vertex array.
    id<MTLBuffer> _vertexBuffer;
    
    // The number of vertices in our vertex buffer.
    NSUInteger _numVertices;
}

/*
 * [initWithMetalKitView:]
 * Initialize with MetalKit view from which we'll obtain Metal device.
 */
-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
{
    self = [super init];
    if(self)
    {
        NSError *error = NULL;

        // A MTLDevice object provides information about a GPU, but
        // its main purpose is to create other objects that can interact with the GPU.
        _device = mtkView.device;
        
        /// - Create Command Queue - ///
        _commandQueue = [_device newCommandQueue];

        /// - Create Rendering Pipeline - ///
        // Load all the shader files with a .metal file extension in the project
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
        // Load the vertex and fragment function from the library
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        // Create a pipeline descriptor that is used to configure a pipeline state
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Simple Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        // This sample only renders to a single target, the view’s drawable (colorAttachments[0]),
        // whose pixel format is configured by the view itself (colorPixelFormat).
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        // Create the pipeline state
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];
        if (!_pipelineState)
        {
            // Pipeline State creation could fail if we haven't properly set up our pipeline descriptor.
            // If the Metal API validation is enabled, we can find out more information about what
            // went wrong.  (Metal API validation is enabled by default when a debug build is run from Xcode)
            NSLog(@"Failed to created pipeline state, error %@", error);
            return nil;
        }
    }

    return self;
}

/*
 * [mtkView:drawableSizeWillChange:]
 * Called whenever the window size changes (macOS) or a relayout operation,
 * such as a device orientation change, occurs (iOS and tvOS).
 */
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable as we'll pass these values to our vertex shader when we draw.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/*
 * [drawInMTKView:]
 * Called whenever it’s time to render a new frame, as specified by the frame
 * rate (for example, 60 FPS) set on the view’s preferredFramesPerSecond property.
 * This callback is typically the main event that begins the execution of your rendering loop.
 */
- (void)drawInMTKView:(nonnull MTKView *)view
{
    const Vertex quadVertices[] =
    {
        // Pixel positions, RGBA colors
        { { -250,   250 },    { 0, 1, 0, 1 } },
        { {  250,   250 },    { 0, 1, 0, 1 } },
        { { -250,  -250 },    { 0, 1, 0, 1 } },
        
        { {  250,  -250 },    { 0, 1, 0, 1 } },
        { { -250,  -250 },    { 0, 1, 0, 1 } },
        { {  250,   250 },    { 0, 1, 0, 1 } },
    };

    // Create vertex data
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:sizeof(quadVertices)];
    
    Vertex* currentQuad = vertexData.mutableBytes;

    memcpy(currentQuad, &quadVertices, sizeof(quadVertices));
    
    // Create vertex buffer by allocating storage that can be read by the GPU
    _vertexBuffer = [_device newBufferWithLength:vertexData.length
                                         options:MTLResourceStorageModeShared];
    
    // Copy the vertex data into the vertex buffer by accessing a pointer via
    // the buffer's `contents` property
    memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
    
    // Calculate the number of vertices by dividing the byte length by the size of each vertex
    _numVertices = vertexData.length / sizeof(Vertex);

    // Create a new command buffer for each render pass to the current drawable
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder so we can render into something
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        
        // Set the region of the drawable to which we'll draw.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        [renderEncoder setRenderPipelineState:_pipelineState];
        
        /// - Send Vertex Data to Vertex Function - ///
        // We call -[MTLRenderCommandEncoder setVertexBuffer:offset:atIndex:] to send data in our
        //   preloaded MTLBuffer from our ObjC code here to our Metal 'vertexShader' function
        // This call has 3 arguments
        //   1) buffer - The buffer object containing the data we want passed down
        //   2) offset - They byte offset from the beginning of the buffer which indicates what
        //      'vertexPointer' point to.  In this case we pass 0 so data at the very beginning is
        //      passed down.
        //      We'll learn about potential uses of the offset in future samples
        //   3) index - An integer index which corresponds to the index of the buffer attribute
        //      qualifier of the argument in our 'vertexShader' function.  Note, this parameter is
        //      the same as the 'index' parameter in
        //              -[MTLRenderCommandEncoder setVertexBytes:length:atIndex:]
        //
        [renderEncoder setVertexBuffer:_vertexBuffer
                                offset:0
                               atIndex:VertexInputIndexVertices];
        
        // You send a pointer to `_viewportSize` and also indicate its size
        // The `VertexInputIndexViewportSize` enum value corresponds to the
        // `viewportSizePointer` argument in the `vertexShader` function because its
        //  buffer attribute also uses the `VertexInputIndexViewportSize` enum value
        //  for its index
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:VertexInputIndexViewportSize];
        
        /// - Draw the Quad - ///
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];
        
        [renderEncoder endEncoding];
        
        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

@end
