//
//  PJBlueToothTool.h
//  BlueToothDev
//
//  Created by Jobs Plato on 2020/11/21.
//

#import <Foundation/Foundation.h>

#import "PJDeviceModel.h"


@protocol PJBlueToothToolDelegate <NSObject>

/**
 蓝牙状态变化
 */
- (void)centralManagerDidUpdateState:(CBManagerState) state;

/**
 发现新设备
 */
- (void)didDiscoverPeripheral:(PJDeviceModel*_Nullable) device;

/**
 *  连接外设进度回调
 */
- (void)connectPeripheralProgress:(float) progress;

/**
 *  连接外设成功
 */
- (void)didConnectPeripheral;


@end



NS_ASSUME_NONNULL_BEGIN

@interface PJBlueToothTool : NSObject


@property (retain,nonatomic) NSMutableArray *peripheralArr;//外部设备数组
@property (retain,nonatomic) CBPeripheral *currentPeripheral;//当前连接设备
@property (retain,nonatomic) CBCharacteristic *readCharacteristic;//当前设备读取协议
@property (retain,nonatomic) CBCharacteristic *writeCharacteristic;//当前设备写入协议
@property (retain,nonatomic) NSMutableData *reciveData;//接收数据对象
@property (weak,nonatomic) id<PJBlueToothToolDelegate> delegate;//回调协议

/**
 搜索设备
 */
- (void) scanForPeripheralsWithServices;

/**
 连接设备
 */
- (void) connectPeripheral:(CBPeripheral *) peripheral;

//写数据
-(void)writeChar;



@end

NS_ASSUME_NONNULL_END
