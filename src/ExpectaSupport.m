// Expecta - ExpectaSupport.m
// Copyright (c) 2011 Peter Jihoon Kim
// Licensed under the MIT License.

#import "ExpectaSupport.h"
#import "NSValue+Expecta.h"
#import "NSObject+Expecta.h"
#import "EXPUnsupportedObject.h"
#import "FloatTuple.h"
#import "DoubleTuple.h"

typedef void (^EXPBasicBlock)();

id _EXPObjectify(char *type, ...) {
  va_list v;
  va_start(v, type);
  id obj = nil;
  if(strcmp(type, @encode(char)) == 0) {
    char actual = (char)va_arg(v, int);
    obj = [NSNumber numberWithChar:actual];
  } else if(strcmp(type, @encode(double)) == 0) {
    double actual = (double)va_arg(v, double);
    obj = [NSNumber numberWithDouble:actual];
  } else if(strcmp(type, @encode(float)) == 0) {
    float actual = (float)va_arg(v, double);
    obj = [NSNumber numberWithFloat:actual];
  } else if(strcmp(type, @encode(int)) == 0) {
    int actual = (int)va_arg(v, int);
    obj = [NSNumber numberWithInt:actual];
  } else if(strcmp(type, @encode(long)) == 0) {
    long actual = (long)va_arg(v, long);
    obj = [NSNumber numberWithLong:actual];
  } else if(strcmp(type, @encode(long long)) == 0) {
    long long actual = (long long)va_arg(v, long long);
    obj = [NSNumber numberWithLongLong:actual];
  } else if(strcmp(type, @encode(short)) == 0) {
    short actual = (short)va_arg(v, int);
    obj = [NSNumber numberWithShort:actual];
  } else if(strcmp(type, @encode(unsigned char)) == 0) {
    unsigned char actual = (unsigned char)va_arg(v, unsigned int);
    obj = [NSNumber numberWithUnsignedChar:actual];
  } else if(strcmp(type, @encode(unsigned int)) == 0) {
    unsigned int actual = (int)va_arg(v, unsigned int);
    obj = [NSNumber numberWithUnsignedInt:actual];
  } else if(strcmp(type, @encode(unsigned long)) == 0) {
    unsigned long actual = (unsigned long)va_arg(v, unsigned long);
    obj = [NSNumber numberWithUnsignedLong:actual];
  } else if(strcmp(type, @encode(unsigned long long)) == 0) {
    unsigned long long actual = (unsigned long long)va_arg(v, unsigned long long);
    obj = [NSNumber numberWithUnsignedLongLong:actual];
  } else if(strcmp(type, @encode(unsigned short)) == 0) {
    unsigned short actual = (unsigned short)va_arg(v, unsigned int);
    obj = [NSNumber numberWithUnsignedShort:actual];
  } else if(strcmp(type, @encode(id)) == 0) {
    id actual = va_arg(v, id);
    obj = actual;
  } else if(strcmp(type, @encode(__typeof__(nil))) == 0) {
    obj = nil;
  } else if(strcmp(type, @encode(EXPBasicBlock)) == 0) {
      EXPUnsupportedObject *actual = [[[EXPUnsupportedObject alloc] initWithType:@"block"] autorelease];
      obj = actual;
  } else if(strstr(type, "ff}{") != NULL) { //TODO: of course this only works for a 2x2 e.g. CGRect
      obj = [[[FloatTuple alloc] initWithFloatValues:(float *)va_arg(v, float[4]) size:4] autorelease];
  } else if(strstr(type, "=ff}") != NULL) {
      obj = [[[FloatTuple alloc] initWithFloatValues:(float *)va_arg(v, float[2]) size:2] autorelease];
  } else if(strstr(type, "=ffff}") != NULL) {
      obj = [[[FloatTuple alloc] initWithFloatValues:(float *)va_arg(v, float[4]) size:4] autorelease];
  } else if(strstr(type, "dd}{") != NULL) { //TODO: same here
      obj = [[[DoubleTuple alloc] initWithDoubleValues:(double *)va_arg(v, double[4]) size:4] autorelease];
  } else if(strstr(type, "=dd}") != NULL) {
      obj = [[[DoubleTuple alloc] initWithDoubleValues:(double *)va_arg(v, double[2]) size:2] autorelease];
  } else if(strstr(type, "=dddd}") != NULL) {
      obj = [[[DoubleTuple alloc] initWithDoubleValues:(double *)va_arg(v, double[4]) size:4] autorelease];
  } else if(type[0] == '{') {
    EXPUnsupportedObject *actual = [[[EXPUnsupportedObject alloc] initWithType:@"struct"] autorelease];
    obj = actual;
  } else if(type[0] == '(') {
    EXPUnsupportedObject *actual = [[[EXPUnsupportedObject alloc] initWithType:@"union"] autorelease];
    obj = actual;
  } else {
    void *actual = va_arg(v, void *);
    obj = (actual == NULL ? nil :[NSValue valueWithPointer:actual]);
  }
  if([obj isKindOfClass:[NSValue class]] && ![obj isKindOfClass:[NSNumber class]]) {
    [(NSValue *)obj set_EXP_objCType:type];
  }
  va_end(v);
  return obj;
}

EXPExpect *_EXP_expect(id testCase, int lineNumber, char *fileName, EXPIdBlock actualBlock) {
  return [EXPExpect expectWithActualBlock:actualBlock testCase:testCase lineNumber:lineNumber fileName:fileName];
}

void EXPFail(id testCase, int lineNumber, char *fileName, NSString *message) {
  NSString *reason = [NSString stringWithFormat:@"%s:%d %@", fileName, lineNumber, message];
  NSException *exception = [NSException exceptionWithName:@"Expecta Error" reason:reason userInfo:nil];
  if(testCase && [testCase respondsToSelector:@selector(failWithException:)]) {
    [testCase failWithException:exception];
  } else {
    [exception raise];
  }
}

NSString *EXPDescribeObject(id obj) {
  if(obj == nil) {
    return @"nil/null";
  } else if([obj isKindOfClass:[NSValue class]]) {
    if([obj isKindOfClass:[NSValue class]] && ![obj isKindOfClass:[NSNumber class]]) {
      void *pointerValue = [obj pointerValue];
      const char *type = [(NSValue *)obj _EXP_objCType];
      if(type) {
        if(strcmp(type, @encode(SEL)) == 0) {
          return [NSString stringWithFormat:@"@selector(%@)", NSStringFromSelector([obj pointerValue])];
        } else if(strcmp(type, @encode(Class)) == 0) {
          return NSStringFromClass(pointerValue);
        }
      }
    }
  }
  return [obj description];
}

void prerequisite(EXPBoolBlock block) {
  [[[[NSThread currentThread] threadDictionary] objectForKey:@"currentMatcher"] setPrerequisiteBlock:block];
}

void match(EXPBoolBlock block) {
  [[[[NSThread currentThread] threadDictionary] objectForKey:@"currentMatcher"] setMatchBlock:block];
}

void failureMessageForTo(EXPStringBlock block) {
  [[[[NSThread currentThread] threadDictionary] objectForKey:@"currentMatcher"] setFailureMessageForToBlock:block];
}

void failureMessageForNotTo(EXPStringBlock block) {
  [[[[NSThread currentThread] threadDictionary] objectForKey:@"currentMatcher"] setFailureMessageForNotToBlock:block];
}

