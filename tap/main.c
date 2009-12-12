#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>

CGEventRef printEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	if (type == 14) return event; // system-defined event
	
	// 0 time 1 type 2 number 3 click state 4 x 5 y 6 command 7 option 8 control 9 shift 10 fn 11 mousewheel
	
	// some sort of time in nanoseconds since Quartz startup
	printf("%lld ", CGEventGetTimestamp(event)/100000000);
	
	// event type
	printf("%d ", type);
	
	// event number
	printf("%lld ", CGEventGetIntegerValueField(event, kCGMouseEventNumber));
	
	// click state (1 = single click, 2 = double click)
	printf("%lld ", CGEventGetIntegerValueField(event, kCGMouseEventClickState));
	
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
	
	//NX_NULLEVENT 0
	//NX_LMOUSEDOWN 1
	//NX_LMOUSEUP 2
	//NX_RMOUSEDOWN 3
	//NX_RMOUSEUP 4
	//NX_MOUSEMOVED 5
	//NX_LMOUSEDRAGGED 6
	//NX_RMOUSEDRAGGED 7
	//NX_KEYDOWN 10
	//NX_KEYUP 11
	//NX_FLAGSCHANGED 12
	//NX_SCROLLWHEELMOVED 22
	//NX_TABLETPOINTER 23
	//NX_TABLETPROXIMITY 24
	//NX_OMOUSEDOWN 25
	//NX_OMOUSEUP 26
	//NX_OMOUSEDRAGGED 26
	
	// from IOLLEvent.h:
	//NX_KITDEFINED		13	/* application-kit-defined event */
	//NX_SYSDEFINED		14	/* system-defined event */
	//NX_APPDEFINED		15	/* application-defined event */
	
	CFRunLoopAddSource(runLoop,  eventSrc, kCFRunLoopDefaultMode);
	CFRunLoopRun();
}