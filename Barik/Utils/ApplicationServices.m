//
//  ApplicationServices.m
//  Barik
//
//  Created by josh on 6/24/26.
//

#import <ApplicationServices/ApplicationServices.h>
#import "ApplicationServices.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

OSStatus og_GetProcessPID(const ProcessSerialNumber *psn, pid_t *pid) { return GetProcessPID(psn, pid); }
