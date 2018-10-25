//
//  GameViewController.m
//  HelloTriangle
//
//  Created by WebQA on 10/16/18.
//  Copyright © 2018 WebQA. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
    MTKView *_view;

    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        self.view = [[NSView alloc] initWithFrame:self.view.frame];
        return;
    }

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];

    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return;
    }

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;
}

@end
