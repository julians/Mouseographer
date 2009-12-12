#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>

CGEventRef printEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	// some sort of time in nanoseconds since Quartz startup
	printf("%lld ", CGEventGetTimestamp(event)/100000000);
	
	// event type
	printf("%d ", type);
	
	// location
	CGPoint loc = CGEventGetLocation(event);
	printf("%f %f ", loc.x, loc.y);
	
	// modifiers
	CGEventFlags flags = CGEventGetFlags(event);
	// command
	if (flags & kCGEventFlagMaskCommand) {
		printf("1 ");
	} else {
		printf("0 ");
	}
	// option
	if (flags & kCGEventFlagMaskAlternate) {
		printf("1 ");
	} else {
		printf("0 ");
	}
	// control
	if (flags & kCGEventFlagMaskControl) {
		printf("1 ");
	} else {
		printf("0 ");
	}
	// shift
	if (flags & kCGEventFlagMaskShift) {
		printf("1 ");
	} else {
		printf("0 ");
	}
	// fn
	if (flags & kCGEventFlagMaskSecondaryFn) {
		printf("1 ");
	} else {
		printf("0 ");
	}
	
	// mousewheel
	printf("%lld ", CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1));
	
	// duh, linebreak
	printf("\n");
	
	return event;
}

int main(int argc, char ** argv)
{
	CFMachPortRef eventPort;
	CFRunLoopSourceRef  eventSrc;
	CFRunLoopRef    runLoop;
	
	eventPort = CGEventTapCreate(kCGSessionEventTap,
                                 kCGHeadInsertEventTap,
                                 kCGEventTapOptionListenOnly,
                                 kCGEventMaskForAllEvents,
                                 printEventCallback,
                                 NULL );
	if ( eventPort == NULL )
	{
		printf( "NULL event port\n" );
		exit( 1 );
	}
	
	eventSrc = CFMachPortCreateRunLoopSource(NULL, eventPort, 0);
	if ( eventSrc == NULL )
		printf( "No event run loop src?\n" );
	
	runLoop = CFRunLoopGetCurrent();
	if ( runLoop == NULL )
		printf( "No run loop?\n" );
	
	CFRunLoopAddSource(runLoop,  eventSrc, kCFRunLoopDefaultMode);
	CFRunLoopRun();
}