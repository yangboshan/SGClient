//
//  SGScanViewController.m
//  SGClient
//
//  Created by JY on 14-6-15.
//  Copyright (c) 2014年 XLDZ. All rights reserved.
//

#import "SGScanViewController.h"

@interface SGScanViewController ()

@end

@implementation SGScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%f  %f",self.view.frame.size.width,self.view.frame.size.height);
    
    self.view.backgroundColor = [UIColor whiteColor];
	UIButton * scanButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [scanButton setTitle:@"取消" forState:UIControlStateNormal];
    [scanButton.titleLabel setFont:[UIFont systemFontOfSize:20.0]];
    scanButton.frame = CGRectMake(250, 500, 120, 40);
    [scanButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanButton];
    
    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(50, 40, 500, 50)];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.textColor=[UIColor whiteColor];
    labIntroudction.text=@"将二维码图像置于矩形方框内，离摄像头10CM左右。";
    [self.view addSubview:labIntroudction];
    
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(150, 150, 300, 300)];
    imageView.image = [UIImage imageNamed:@"pick_bg"];
    [self.view addSubview:imageView];
    
    upOrdown = NO;
    num =0;
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(190, 160, 220, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:_line];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
}

-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(190, 160+2*num, 220, 2);
        if (2*num == 280) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(190, 160+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
}
-(void)backAction
{
    [self dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
    }];
}
-(void)viewWillAppear:(BOOL)animated
{
    [self setupCamera];
    [self setOrientationForCamara:self.interfaceOrientation];
}
- (void)setupCamera
{
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];

    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame =CGRectMake(0,0,600,600);
    [self.view.layer insertSublayer:self.preview atIndex:0];

    [_session startRunning];
}
#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    [_session stopRunning];
    
    [self dismissViewControllerAnimated:YES completion:^
     {
         [timer invalidate];
         NSLog(@"%@",stringValue);
         
         NSArray* result = [stringValue componentsSeparatedByString:@":"];
         [self.mainController.leftDock setDefaultSelected];
         
         if ([stringValue rangeOfString:@"C"].location!=NSNotFound) {
             if (result.count == 3) {
                 [self.mainController.currentChild popToRootViewControllerAnimated:NO];
                 SGMainViewController* mainController = (SGMainViewController*)self.mainController.currentChild.childViewControllers[0];
                 [mainController scanModeWithCubicleId:[result[1] integerValue] withCableId:[result[2] integerValue]];
             }
         }
         
         if ([stringValue rangeOfString:@"F"].location!=NSNotFound) {
             if (result.count == 2) {
                 [self.mainController.currentChild popToRootViewControllerAnimated:NO];
                 SGMainViewController* mainController = (SGMainViewController*)self.mainController.currentChild.childViewControllers[0];
                 [mainController scanModeWithPortId:result[1]];
             }
         }
       }];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    [self setOrientationForCamara:toInterfaceOrientation];
}

-(void)setOrientationForCamara:(UIInterfaceOrientation)orientation{
    
    AVCaptureConnection *previewLayerConnection=self.preview.connection;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            break;
    }
    
}


@end
