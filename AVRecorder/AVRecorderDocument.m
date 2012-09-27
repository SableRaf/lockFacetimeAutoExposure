#import "AVRecorderDocument.h"
#import <AVFoundation/AVFoundation.h>

@interface AVRecorderDocument ()

// Properties for internal use
@property (retain) AVCaptureDeviceInput *videoDeviceInput;
//@property (readonly) BOOL selectedVideoDeviceProvidesAudio;
@property (retain) AVCaptureVideoPreviewLayer *previewLayer;

// Methods for internal use
- (void)refreshDevices;

@end

@implementation AVRecorderDocument

@synthesize videoDeviceInput;
@synthesize videoDevices;
@synthesize session;
@synthesize isLocked;
@synthesize previewView;
@synthesize previewLayer;


- (id)init
{
	self = [super init];
	if (self) {
		// Create a capture session
		session = [[AVCaptureSession alloc] init];         
		
		// Select devices if any exist
		AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		if (videoDevice) {
			[self setSelectedVideoDevice:videoDevice];
		} else {
			[self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
		}
		
		// Initial refresh of device list
		[self refreshDevices];
	}
	return self;
}

- (NSString *)windowNibName
{
	return @"AVRecorderDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	[super windowControllerDidLoadNib:aController];
	
	// Attach preview to session
	CALayer *previewViewLayer = [[self previewView] layer];
	[previewViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
	AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]];
	[newPreviewLayer setFrame:[previewViewLayer bounds]];
	[newPreviewLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
	[previewViewLayer addSublayer:newPreviewLayer];
	[self setPreviewLayer:newPreviewLayer];
	[newPreviewLayer release];
	
	// Start the session
	[[self session] startRunning];
	
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void  *)contextInfo
{
	// Do nothing
}


/********** Manage video sources **********/

- (void)refreshDevices
{
	[self setVideoDevices:[[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]]];

	[[self session] beginConfiguration];
	
	if (![[self videoDevices] containsObject:[self selectedVideoDevice]])
		[self setSelectedVideoDevice:nil];
	
	[[self session] commitConfiguration];
}

- (AVCaptureDevice *)selectedVideoDevice
{
	return [videoDeviceInput device];
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    NSLog(@"device changed to \"%@\"", selectedVideoDevice.localizedName);
    
    // Remove any remaining lock on the device
    [self unlockDevice:selectedVideoDevice];

    [[self session] beginConfiguration];
    
    if ([self videoDeviceInput]) {
        // Remove the old device input from the session
        [session removeInput:[self videoDeviceInput]];
        [self setVideoDeviceInput:nil];
    }
    
    if (selectedVideoDevice) {
        NSError *error = nil;
        
        // Create a device input for the device and add it to the session
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];
        if (newVideoDeviceInput == nil) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentError:error];
            });
        } else {
            if (![selectedVideoDevice supportsAVCaptureSessionPreset:[session sessionPreset]])
                [[self session] setSessionPreset:AVCaptureSessionPresetHigh];
            
            [[self session] addInput:newVideoDeviceInput];
            [self setVideoDeviceInput:newVideoDeviceInput];
        }
    }
    
    [[self session] commitConfiguration];
}


/********** Manage exposure locking/unlocking **********/

- (IBAction)switchLockAutoExposure:(id)sender
{
    self.isLocked=!self.getIsLocked;
	[self setLockExposure:(BOOL)self.getIsLocked];
}
 
- (void)setLockExposure:(BOOL)locked
{
    AVCaptureDevice *device = [self selectedVideoDevice];
    if(locked) {
        if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            NSError *error = nil;
            if ([device lockForConfiguration:&error]) {
                device.exposureMode = AVCaptureExposureModeLocked;
                NSLog(@"Auto-exposure is now locked");
            }
            else {
                NSLog(@"%@ couldn't be locked", device.localizedName);
            }
        } else {
            NSLog(@"%@ does not support Auto-Exposure locking", device.localizedName);
        }
        
    } else {
        if (device.exposureMode == AVCaptureExposureModeLocked) {
            [self unlockDevice:device];
        }
	}
}

-(void)unlockDevice:(AVCaptureDevice *)device
{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        //[device lockForConfiguration];
        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        [device unlockForConfiguration];
        NSLog(@"%@ successfully unlocked", device.localizedName);
    }
    else {
        NSLog(@"%@ can't be unlocked", device.localizedName);
        // Respond to the failure as appropriate.
    }
}

- (void)unlockAllDevices
{
    NSLog(@"Unlocking all devices...");
    NSUInteger i = [videoDevices count]; while ( i-- ) {
        //AVCaptureDevice *device = [videoDevices objectAtIndex:i];
        [self unlockDevice:[videoDevices objectAtIndex:i]];
    }
}


/********** End the program **********/

- (void)windowWillClose:(NSNotification *)notification
{
    [self unlockAllDevices];
	[[self session] stopRunning];
}

- (void)dealloc
{
	[videoDevices release];
	[session release];
	[previewLayer release];
	[videoDeviceInput release];
	
	[super dealloc];
}


@end
