#import <Cocoa/Cocoa.h>

@class AVCaptureVideoPreviewLayer;
@class AVCaptureSession;
@class AVCaptureDeviceInput;
@class AVCaptureConnection;
@class AVCaptureDevice;

@interface AVRecorderDocument : NSDocument
{
@private
	NSView						*previewView;
	AVCaptureVideoPreviewLayer	*previewLayer;
	
	AVCaptureSession			*session;
	AVCaptureDeviceInput		*videoDeviceInput;
	
	NSArray						*videoDevices;

}

@property (retain) NSArray *videoDevices;
@property (assign) AVCaptureDevice *selectedVideoDevice;
@property (retain) AVCaptureSession *session;
@property (readonly) NSArray *availableSessionPresets;
@property (assign,getter=getIsLocked,setter=setIsLocked:) BOOL isLocked;
@property (assign) IBOutlet NSView *previewView;

- (IBAction)switchLockAutoExposure:(id)sender;

@end
