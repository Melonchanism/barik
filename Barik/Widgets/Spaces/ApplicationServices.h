//
//  ApplicationServices.h
//  Barik
//
//  Created by josh on 6/17/26.
//

#import <ApplicationServices/ApplicationServices.h>
#import "ApplicationServices.h"

OSStatus og_GetProcessPID(const ProcessSerialNumber *psn, pid_t *pid) { return GetProcessPID(psn, pid); }
