//
// UTCMenuClockAppDelegate.m
// UTCMenuClock
//
// Created by John Adams on 11/14/11.
//
// Copyright 2011-2016 John Adams
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UTCMenuClockAppDelegate.h"
#import "LaunchAtLoginController.h"

@implementation UTCMenuClockAppDelegate

@synthesize window;
@synthesize mainMenu;

NSStatusItem *ourStatus;
NSMenuItem *dateMenuItem;
NSMenuItem *showTimeZoneItem;
NSMenuItem *showDayOfWeekItem;

- (void) quitProgram:(id)sender {
    // Cleanup here if necessary...
    [[NSApplication sharedApplication] terminate:nil];
}

- (void) toggleLaunch:(id)sender {
    NSInteger state = [sender state];
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];

    if (state == NSOffState) {
        [sender setState:NSOnState];
        [launchController setLaunchAtLogin:YES];
    } else {
        [sender setState:NSOffState];
        [launchController setLaunchAtLogin:NO];
    }

    [launchController release];
}

- (BOOL) fetchBooleanPreference:(NSString *)preference {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    BOOL value = [standardUserDefaults boolForKey:preference];
    return value;
}

- (void) togglePreference:(id)sender {
    NSInteger state = [sender state];
    NSString *preference = [sender title];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    preference = [preference stringByReplacingOccurrencesOfString:@" "
                                                       withString:@""];
    if (state == NSOffState) {
        [sender setState:NSOnState];
        [standardUserDefaults setBool:TRUE forKey:preference];
    } else {
        [sender setState:NSOffState];
        [standardUserDefaults setBool:FALSE forKey:preference];
    }

}

- (void) openGithubURL:(id)sender {
    [[NSWorkspace sharedWorkspace]
        openURL:[NSURL URLWithString:@"http://github.com/netik/UTCMenuClock"]];
}


- (void) doDateUpdate {

    NSDate* date = [NSDate date];
    NSDateFormatter* UTCdf = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* UTCdateDF = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* UTCdateShortDF = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* UTCdaynum = [[[NSDateFormatter alloc] init] autorelease];
    NSDateFormatter* UTCdayOfWeekDF = [[[NSDateFormatter alloc] init] autorelease];
    
    NSTimeZone* UTCtz = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];

    [UTCdf setTimeZone: UTCtz];
    [UTCdateDF setTimeZone: UTCtz];
    [UTCdateShortDF setTimeZone: UTCtz];
    [UTCdaynum setTimeZone: UTCtz];

    BOOL showDate = [self fetchBooleanPreference:@"ShowDate"];
    BOOL showSeconds = [self fetchBooleanPreference:@"ShowSeconds"];
    BOOL showJulian = [self fetchBooleanPreference:@"ShowJulianDate"];
    BOOL showDayOfWeek = [self fetchBooleanPreference:@"ShowDayOfWeek"];
    BOOL showTimeZone = [self fetchBooleanPreference:@"ShowTimeZone"];
    BOOL show24HrTime = [self fetchBooleanPreference:@"24HRTime"];
    
    if (showSeconds) {
        if (show24HrTime){
            [UTCdf setDateFormat: @"HH:mm:ss"];
        } else {
            [UTCdf setDateFormat: @"hh:mm:ss a"];
        }
    } else {
        if (show24HrTime){
            [UTCdf setDateFormat: @"HH:mm"];
        } else {
            [UTCdf setDateFormat: @"hh:mm a"];
        }
    }
    [UTCdateDF setDateStyle:NSDateFormatterFullStyle];
    [UTCdateShortDF setDateFormat:@"MM/dd/yy "];
    [UTCdaynum setDateFormat:@"D/"];
    [UTCdayOfWeekDF setDateFormat:@"EEE "];

    NSString* UTCtimepart = [UTCdf stringFromDate: date];
    NSString* UTCdatepart = [UTCdateDF stringFromDate: date];
    NSString* UTCdateShort;
    NSString* UTCJulianDay;
    NSString* UTCdayOfWeekPart;
    NSString* UTCTzString;
    
    
    if (showJulian) { 
        UTCJulianDay = [UTCdaynum stringFromDate: date];
    } else { 
        UTCJulianDay = @"";
    }
    
    if (showTimeZone) { 
        UTCTzString = @" UTC";
    } else { 
        UTCTzString = @"";
    }
    
    if (showDayOfWeek) {
        UTCdayOfWeekPart = [UTCdayOfWeekDF stringFromDate: date];
    } else {
        UTCdayOfWeekPart = @"";
    }

    if (showDate) {
        UTCdateShort = [UTCdateShortDF stringFromDate: date];
    } else {
        UTCdateShort = @"";
    }

    [ourStatus setTitle:[NSString stringWithFormat:@"%@%@%@%@%@", UTCdayOfWeekPart, UTCdateShort, UTCJulianDay, UTCtimepart, UTCTzString]];
    
    [dateMenuItem setTitle:UTCdatepart];

}

- (IBAction)showFontMenu:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setDelegate:self];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:sender];
}
// this is the main work loop, fired on 1s intervals.
- (void) fireTimer:(NSTimer*)theTimer {
    [self doDateUpdate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // set our default preferences if they've never been set before.
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *dateKey    = @"dateKey";
    NSDate *lastRead    = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:dateKey];
    if (lastRead == nil)     // App first run: set up user defaults.
    {
        NSDictionary *appDefaults  = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], dateKey, nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:dateKey];

        [standardUserDefaults setBool:TRUE forKey:@"ShowTimeZone"];
        [standardUserDefaults setBool:TRUE forKey:@"ShowDayOfWeek"];
        [showTimeZoneItem setState:NSOnState];
        [showDayOfWeekItem setState:NSOnState];
    }
    [self doDateUpdate];

}

- (void)awakeFromNib
{
    mainMenu = [[NSMenu alloc] init];

    //Create Image for menu item
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    NSStatusItem *theItem;
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [theItem retain];
    // retain a reference to the item so we don't have to find it again
    ourStatus = theItem;

    //Set Image
    //[theItem setImage:(NSImage *)menuicon];
    [theItem setTitle:@""];

    //Make it turn blue when you click on it
    [theItem setHighlightMode:YES];
    [theItem setEnabled: YES];

    // build the menu
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    dateMenuItem = mainItem;

    NSMenuItem *cp1Item = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *quitItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *launchItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *showDateItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *show24Item = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *showSecondsItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *showJulianItem = [[[NSMenuItem alloc] init] autorelease];
 //   NSMenuItem *changeFontItem = [[[NSMenuItem alloc] init] autorelease];
    
    showDayOfWeekItem = [[[NSMenuItem alloc] init] autorelease];
    showTimeZoneItem = [[[NSMenuItem alloc] init] autorelease];
    NSMenuItem *sep1Item = [NSMenuItem separatorItem];
    NSMenuItem *sep2Item = [NSMenuItem separatorItem];
    NSMenuItem *sep3Item = [NSMenuItem separatorItem];
    
    [mainItem setTitle:@""];

    [cp1Item setTitle:@"UTC Menu Clock v1.2.4"];

    [launchItem setTitle:@"Open at Login"];
    [launchItem setEnabled:TRUE];
    [launchItem setAction:@selector(toggleLaunch:)];

    [show24Item setTitle:@"24 HR Time"];
    [show24Item setEnabled:TRUE];
    [show24Item setAction:@selector(togglePreference:)];
    
    [showDateItem setTitle:@"Show Date"];
    [showDateItem setEnabled:TRUE];
    [showDateItem setAction:@selector(togglePreference:)];

    [showSecondsItem setTitle:@"Show Seconds"];
    [showSecondsItem setEnabled:TRUE];
    [showSecondsItem setAction:@selector(togglePreference:)];
    
    [showJulianItem setTitle:@"Show Julian Date"];
    [showJulianItem setEnabled:TRUE];
    [showJulianItem setAction:@selector(togglePreference:)];
    
    [showDayOfWeekItem setTitle:@"Show Day Of Week"];
    [showDayOfWeekItem setEnabled:TRUE];
    [showDayOfWeekItem setAction:@selector(togglePreference:)];

    [showTimeZoneItem setTitle:@"Show Time Zone"];
    [showTimeZoneItem setEnabled:TRUE];
    [showTimeZoneItem setAction:@selector(togglePreference:)];
    
 //   [changeFontItem setTitle:@"Change Font..."];
  //  [changeFontItem setAction:@selector(showFontMenu:)];
    
    [quitItem setTitle:@"Quit"];
    [quitItem setEnabled:TRUE];
    [quitItem setAction:@selector(quitProgram:)];

    [mainMenu addItem:mainItem];
    // "---"
    [mainMenu addItem:sep2Item];
    // "---"
    [mainMenu addItem:cp1Item];
    // "---"
    [mainMenu addItem:sep1Item];

    // showDateItem
    BOOL showDate = [self fetchBooleanPreference:@"ShowDate"];
    BOOL showSeconds = [self fetchBooleanPreference:@"ShowSeconds"];
    BOOL showJulian = [self fetchBooleanPreference:@"ShowJulianDate"];
    BOOL showDayOfWeek = [self fetchBooleanPreference:@"ShowDayOfWeek"];
    BOOL showTimeZone = [self fetchBooleanPreference:@"ShowTimeZone"];
    BOOL show24HrTime = [self fetchBooleanPreference:@"24HRTime"];
    
    // TODO: DRY this up a bit.
    
    if (show24HrTime) {
        [show24Item setState:NSOnState];
    } else {
        [show24Item setState:NSOffState];
    }
    
    if (showDate) {
        [showDateItem setState:NSOnState];
    } else {
        [showDateItem setState:NSOffState];
    }

    if (showSeconds) {
        [showSecondsItem setState:NSOnState];
    } else {
        [showSecondsItem setState:NSOffState];
    }

    if (showJulian) {
        [showJulianItem setState:NSOnState];
    } else {
        [showJulianItem setState:NSOffState];
    }
    
    if (showDayOfWeek) {
        [showDayOfWeekItem setState:NSOnState];
    } else {
        [showDayOfWeekItem setState:NSOffState];
    }
    
    if (showTimeZone) {
        [showTimeZoneItem setState:NSOnState];
    } else {
        [showTimeZoneItem setState:NSOffState];
    }
    
    // latsly, deal with Launch at Login
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    BOOL launch = [launchController launchAtLogin];
    [launchController release];

    if (launch) {
        [launchItem setState:NSOnState];
    } else {
        [launchItem setState:NSOffState];
    }

    [mainMenu addItem:launchItem];
    [mainMenu addItem:show24Item];
    [mainMenu addItem:showDateItem];
    [mainMenu addItem:showSecondsItem];
    [mainMenu addItem:showJulianItem];
    [mainMenu addItem:showDayOfWeekItem];
    [mainMenu addItem:showTimeZoneItem];
  //  [mainMenu addItem:changeFontItem];
    // "---"
    [mainMenu addItem:sep3Item];
    [mainMenu addItem:quitItem];

    [theItem setMenu:(NSMenu *)mainMenu];

    // Update the date immediately after setup so that there is no timer lag
    [self doDateUpdate];

    NSNumber *myInt = [NSNumber numberWithInt:1];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:) userInfo:myInt repeats:YES];


}

@end
