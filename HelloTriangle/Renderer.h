//
//  Renderer.h
//  Header for platform independent renderer class, which initializes Metal setup and per-frame Metal commands.
//
//  Created by WebQA on 10/16/18.
//  Copyright © 2018 WebQA. All rights reserved.
//

#import <MetalKit/MetalKit.h>

// Our platform independent renderer class.
// Implements the MTKViewDelegate protocol which allows it to accept per-frame update and drawable resize callbacks.
@interface Renderer : NSObject <MTKViewDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkview;

@end

