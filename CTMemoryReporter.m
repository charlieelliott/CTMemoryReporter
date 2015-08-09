//
//  CTMemoryReporter.m
//
//  Copyright (c) 2015 Charlie Elliott
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CTMemoryReporter.h"
#import "mach/mach.h"

static CTMemoryReporter *__sharedInstance;

@interface CTMemoryReporter()
@property (nonatomic) NSTimer *timer;
@end

@implementation CTMemoryReporter

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [self new];
    });
    
    return __sharedInstance;
}

# pragma mark - Interface

- (void)beginReportingMemoryToConsoleWithInterval:(NSTimeInterval)interval
{
    if(self.timer)
        [self endReportingMemoryToConsole];
    
    [self memoryReportingTic]; //call the first time right away
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(memoryReportingTic) userInfo:nil repeats:YES];
}

- (void)endReportingMemoryToConsole
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)reportMemoryToConsoleWithReferrer:(NSString *)referrer
{
    struct task_basic_info kerBasicInfo;
    mach_msg_type_number_t kerBasicSize = sizeof(kerBasicInfo);
    kern_return_t kerBasic = task_info(mach_task_self(),
                                       TASK_BASIC_INFO,
                                       (task_info_t)&kerBasicInfo,
                                       &kerBasicSize);
    
    struct task_kernelmemory_info kerMemInfo;
    mach_msg_type_number_t kerMemSize = sizeof(kerMemInfo);
    kern_return_t kerMem = task_info(mach_task_self(),
                                     TASK_KERNELMEMORY_INFO,
                                     (task_info_t)&kerMemInfo,
                                     &kerMemSize);
    
    if(kerBasic == KERN_SUCCESS && kerMem == KERN_SUCCESS)
    {
        NSLog(@"∆∆∆ %@ : \n\
              resident_size: %.2f MB virtual_size: %.2f MB\n\
              private alloc: %.2f MB free: %.2f MB\n\
              shared alloc: %.2f MB free: %.2f MB",
              referrer, (float)kerBasicInfo.resident_size/(1024.f*1024.f), (float)kerBasicInfo.virtual_size/(1024.f*1024.f),
              (float)kerMemInfo.total_palloc/(1024.f*1024.f), (float)kerMemInfo.total_pfree/(1024.f*1024.f),
              (float)kerMemInfo.total_salloc/(1024.f*1024.f), (float)kerMemInfo.total_sfree/(1024.f*1024.f));
    }
    else
        NSLog(@"∆•∆ %@ : Error with task_info(): %s", referrer, mach_error_string(kerBasic));
}

# pragma mark - Internal

- (void)memoryReportingTic
{
    [self reportMemoryToConsoleWithReferrer:@"Memory Reporting Loop"];
}

@end
