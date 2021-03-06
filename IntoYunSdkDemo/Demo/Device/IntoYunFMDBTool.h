//
//  IntoYunFMDBTool.h
//  IntoYunSdkDemo
//
//  Created by hui he on 17/4/11.
//  Copyright © 2017年 hui he. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntoYunSDK.h"
#import "FMDB.h"

@interface IntoYunFMDBTool : NSObject

+ (void)saveDevices:(NSArray *)devices;

+ (void)deleteDeviceWithID:(NSString *)ID;

+ (void)updateDeviceWithID:(NSDictionary *)device;

+ (DeviceModel *)getDeviceWithID:(NSString *)ID;

+ (NSArray *)getDeviceListArray;

+ (void)cleanDevices;


+ (void)saveVirtualDevices:(NSMutableDictionary *)device;

+ (void)deleteVirtualDeviceWithID:(NSString *)ID;


+ (DeviceModel *)getVirtualDeviceWithID:(NSString *)ID;

+ (NSArray *)getVirtualDeviceListArray;

+ (void)cleanVirtualDevices;



+ (void)saveDatapoints:(NSDictionary *)datapoints;

+ (DatapointModel *)getDatapointWithDpID:(NSString *)productID dpID:(int)dpId;

+ (NSArray *)getDatapointListArray:(NSString *)productID;

+ (void)cleanDatapoints;

@end
