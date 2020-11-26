//
//  PJDeviceModel.h
//  BlueToothDev
//
//  Created by Jobs Plato on 2020/11/21.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
NS_ASSUME_NONNULL_BEGIN

@interface PJDeviceModel : NSObject

@property(nonatomic,copy)NSString *deviceName;
@property(nonatomic,strong)CBPeripheral *peripheral;
@property(nonatomic,assign)NSUInteger rssi;
@property(nonatomic,copy)NSString *macAddress;


@end

NS_ASSUME_NONNULL_END
