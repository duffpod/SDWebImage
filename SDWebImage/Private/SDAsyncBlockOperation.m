/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDAsyncBlockOperation.h"
#import "SDInternalMacros.h"

@interface SDAsyncBlockOperation ()

@property (nonatomic, copy, nonnull) SDAsyncBlock executionBlock;

@end

@implementation SDAsyncBlockOperation {
    BOOL _executing;
    BOOL _finished;
}

- (nonnull instancetype)initWithBlock:(nonnull SDAsyncBlock)block {
    self = [super init];
    if (self) {
        self.executionBlock = block;
    }
    return self;
}

+ (nonnull instancetype)blockOperationWithBlock:(nonnull SDAsyncBlock)block {
    SDAsyncBlockOperation *operation = [[SDAsyncBlockOperation alloc] initWithBlock:block];
    return operation;
}

- (void)start {
    BOOL cancelled;
    @synchronized (self) {
        cancelled = self.isCancelled;
        if (cancelled) {
            [self willChangeValueForKey:@"isFinished"];
            _finished = YES;
        } else {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _finished = NO;
            _executing = YES;
        }
    }
    if (cancelled) {
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    SDAsyncBlock executionBlock = self.executionBlock;
    if (executionBlock) {
        @weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @strongify(self);
            if (!self) return;
            executionBlock(self);
        });
    }
}

- (void)cancel {
    BOOL wasExecuting;
    @synchronized (self) {
        [super cancel];
        wasExecuting = _executing;
        if (wasExecuting) {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _executing = NO;
            _finished = YES;
        }
    }
    if (wasExecuting) {
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (void)complete {
    BOOL wasExecuting;
    @synchronized (self) {
        wasExecuting = _executing;
        if (wasExecuting) {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _finished = YES;
            _executing = NO;
        }
    }
    if (wasExecuting) {
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)isFinished {
    @synchronized (self) {
        return _finished;
    }
}

- (BOOL)isExecuting {
    @synchronized (self) {
        return _executing;
    }
}

- (BOOL)isAsynchronous {
    return YES;
}

@end
