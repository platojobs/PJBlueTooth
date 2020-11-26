//
//  PJBlueToothTool.m
//  BlueToothDev
//
//  Created by Jobs Plato on 2020/11/21.
//

#import "PJBlueToothTool.h"

@interface PJBlueToothTool ()<CBCentralManagerDelegate,CBPeripheralDelegate>


@property (retain,nonatomic) CBCentralManager *centralManger;//中心管理器

@property (copy,nonatomic) NSString *tagDeviceMac;//指定设备连接


@end



@implementation PJBlueToothTool


- (id) init{
    if(self = [super init]){
        
    }
    return self;
}

/**
 搜索设备
 */
- (void) scanForPeripheralsWithServices{
    _peripheralArr = [[NSMutableArray alloc] init];

    if(self.delegate && [self.delegate respondsToSelector:@selector(connectPeripheralProgress:)]){
        //搜索设备，回调进度
        [self.delegate connectPeripheralProgress:0.1];
    }
    if(!self.centralManger){
        self.centralManger = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
    }else{
        [self stop];
        if ([self.centralManger state] == CBManagerStatePoweredOn) {
            [self.centralManger scanForPeripheralsWithServices:nil options:nil];
        }
    }
}

/**
 连接设备
 */
- (void) connectPeripheral:(CBPeripheral *) peripheral{
    peripheral.delegate = self;
    [self.centralManger connectPeripheral:peripheral options:nil];
}

#pragma 蓝牙扫描与连接

/**
 *  扫描外部设备
 *  scanForPeripheralsWithServices ：如果传入指定的数组，那么就只会扫描数组中对应ID的设备
 *                                   如果传入nil，那么就是扫描所有可以发现的设备
 *  扫描完外部设备就会通知CBCentralManager的代理
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([central state] == CBManagerStatePoweredOn) {
        [self.centralManger scanForPeripheralsWithServices:nil options:nil];
//        [self.centralManger scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"00001524-1212-EFDE-1523-785FEABCD123"]] options:nil];
    }
}

/**
 *  发现外部设备，每发现一个就会调用这个方法
 *  所以可以使用一个数组来存储每次扫描完成的数组
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    // 有可能会导致重复添加扫描到的外设
    // 所以需要先判断数组中是否包含这个外设
    if(![_peripheralArr containsObject:peripheral] && peripheral.name != nil){
        [_peripheralArr addObject:peripheral];
        NSLog(@"new device:%@,%@",peripheral.identifier.UUIDString,advertisementData);
        
        NSData *data =  advertisementData[@"kCBAdvDataManufacturerData"];
 
        if (data && data.length >= 3) {
            //mac = [mac stringByReplacingOccurrencesOfString:@" " withString:@""];
            long num= data.length;
            unsigned char *recData = malloc(num);
            [data getBytes:recData length:data.length];
            NSMutableString *mac = [NSMutableString string];
            
            for (int i = 0; i < num; i++) {
                if (i != num-1) {
                    [mac appendString:[NSString stringWithFormat:@"%02x:",recData[i]]];
                }else{
                    [mac appendString:[NSString stringWithFormat:@"%02x",recData[i]]];
                }
            }
            
            NSString *bandMac = [[NSUserDefaults standardUserDefaults] objectForKey:@"CURRENTMAC"];//当前的mac设备
            if (bandMac == nil && ![bandMac isEqualToString:mac]) {
                return;
            }
         
            PJDeviceModel *device = [[PJDeviceModel alloc] init];
            device.deviceName = peripheral.name;
            device.peripheral = peripheral;
            device.rssi = [RSSI intValue];
            device.macAddress = [mac uppercaseString];
            NSLog(@"mac:%@",device.macAddress);
            //回调刷新(搜索连接)
            if(self.delegate && [self.delegate respondsToSelector:@selector(didDiscoverPeripheral:)]){
                [self.delegate didDiscoverPeripheral:device];
            //二维码
            }else if(self.delegate && [self.delegate respondsToSelector:@selector(connectPeripheralProgress:)]){
                if(self.tagDeviceMac && [device.macAddress isEqualToString:self.tagDeviceMac]){
                    //匹配到设备,停止扫描
                    [self.centralManger stopScan];
                    //发现指定设备并连接，回调进度
                    [self.delegate connectPeripheralProgress:0.3];
                    //自动连接
                    [self connectPeripheral:peripheral];
                }
            }
            
            if (recData) {
                free(recData);
            }
            
        }
        
        
        /*
        PJDeviceModel *device = [[PJDeviceModel alloc] init];
        device.deviceName = peripheral.name;
        device.peripheral = peripheral;
        device.rssi = [RSSI intValue];
        device.macAddress = [self getMacString:data];
        //回调刷新(搜索连接)
        if(self.delegate && [self.delegate respondsToSelector:@selector(didDiscoverPeripheral:)]){
            [self.delegate didDiscoverPeripheral:device];
            //二维码
        }else if(self.delegate && [self.delegate respondsToSelector:@selector(connectPeripheralProgress:)]){
            if(self.tagDeviceMac && [device.macAddress isEqualToString:self.tagDeviceMac]){
                //匹配到设备,停止扫描
                [self.centralManger stopScan];
                //发现指定设备并连接，回调进度
                [self.delegate connectPeripheralProgress:0.3];
                //自动连接
                [self connectPeripheral:peripheral];
            }
        }
         */
        
    }
}


/**
 *  断开连接
 */
- (void)stop
{
    [self.centralManger stopScan];
    // 断开所有连接上的外设
    for (CBPeripheral *per in _peripheralArr) {
        [self.centralManger cancelPeripheralConnection:per];
    }
}

/**
 *  连接外设成功调用
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    if(self.tagDeviceMac && self.delegate && [self.delegate respondsToSelector:@selector(connectPeripheralProgress:)]){
        //成功连接设备，回调进度
        [self.delegate connectPeripheralProgress:0.5];
    }

    _currentPeripheral = peripheral;
    // 查找外设服务
    [peripheral discoverServices:nil];
   
    
}

/**
 连接外设失败
 */
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@",error);
}

/**
 *  发现服务就会调用代理方法
 *
 *  @param peripheral 外设
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(self.tagDeviceMac && self.delegate && [self.delegate respondsToSelector:@selector(connectPeripheralProgress:)]){
        //发现服务，回调进度
        [self.delegate connectPeripheralProgress:0.6];
    }
    // 扫描到设备的所有服务
    NSArray *services = peripheral.services;
    // 根据服务再次扫描每个服务对应的特征
    for (CBService *ses in services) {
        [peripheral discoverCharacteristics:nil forService:ses];
    }
}

/**
 *  发现服务对应的特征
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    // 服务对应的特征
    NSArray *ctcs = service.characteristics;
    BOOL foundService = NO;
    // 遍历所有的特征
    for (CBCharacteristic *character in ctcs) {
        NSLog(@"uuid:%@",character.UUID.UUIDString);
        [_currentPeripheral readValueForCharacteristic:character];
        [_currentPeripheral setNotifyValue:YES forCharacteristic:character];
        [_currentPeripheral discoverDescriptorsForCharacteristic:character];
        // 根据特征的唯一标示过滤
        if ([character.UUID.UUIDString isEqualToString:@"0783B03E-8535-B5A0-7140-A304D2495CB8"]) {
            //保存读取协议
            _readCharacteristic = character;
            //0783B03E-8535-B5A0-7140-A304D2495CBA
        }else if ([character.UUID.UUIDString isEqualToString:@"00001532-1212-EFDE-1523-785FEABCD123"]) {
            //保存写入协议
            _writeCharacteristic = character;
            
        }else if([character.UUID.UUIDString isEqualToString:@"0783B03E-8535-B5A0-7140-A304D2495CB9"]){
            //流协议，暂不处理
        }
        foundService = YES;
    }
    
    //发现可用服务后回调刷新
    if(foundService && self.delegate && [self.delegate respondsToSelector:@selector(didConnectPeripheral)]){
        [self.delegate didConnectPeripheral];
    }else  if(self.tagDeviceMac && self.delegate && [self.delegate respondsToSelector:@selector(connectPeripheralProgress:)]){
        //发现可用服务，回调进度
        [self.delegate connectPeripheralProgress:1];
    }

    
}

//写数据
-(void)writeChar
{
    char Timer[8] ={0,1,2,3,4,5,6,7};
    NSData *TimerData = [[NSData alloc] initWithBytes:Timer length:sizeof(Timer)];
    
    uint16_t val = 0;
    NSData * valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
    
    //    for ( CBService *service in _currentPeripheral.services ) {
    //
    //        for ( CBCharacteristic *characteristic in service.characteristics ) {
    //
    //            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0783B03E-8535-B5A0-7140-A304D2495CBA"]]) {
    //                NSLog(@"Characteristic %@ value={%@}",characteristic.UUID,characteristic.value);
    //
    //                [_currentPeripheral writeValue:TimerData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    //            }
    //        }
    //    }
    [_currentPeripheral writeValue:TimerData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    //    NSLog(@"%@;%@",_currentPeripheral,_writeCharacteristic);
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    BOOL Succussed = YES;
    if (error) {
        Succussed = NO;
        NSLog(@" Write error={%@}\n",error);
    }
    
    NSLog(@"Finish Write\n");
    
}
//监听设备
-(void)startSubscribe
{
    [_currentPeripheral setNotifyValue:YES forCharacteristic:_readCharacteristic];
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //按下蓝牙装置的按键在这里收不到任何东西
    
    //这部份都会得到Error = Error Domain=CBErrorDomain Code=0 "Unknown error." UserInfo=0x15555ae0 {NSLocalizedDescription=Unknown error.}
    
    NSLog(@"Notifity = %d,error:%@",characteristic.isNotifying,error);//这边打印出来的值除了2A19的电源打印出来是1，其他都是0。
    
    if (error==nil) {
        
        [peripheral readValueForCharacteristic:characteristic];
        
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"recive data:%@",characteristic);
    if (!error) {
        // NSLog(@"==lenght={%d}=UUId=={%@}==properties={%x}=\n",[characteristic.value length],characteristic.UUID,characteristic.properties);
        
        int length = [characteristic.value length];
        unsigned char *RecData = malloc([characteristic.value length]);
        [characteristic.value getBytes:RecData length:length];
        
        int bit0 = RecData[0]&(0x01);
        int bit1 = (RecData[0]&(1<<0x01))>>1;
        int bit2 = (RecData[0]&(2<<0x01))>>2;
        
        
        if (RecData) {
            
            free(RecData);
        }
    }
    else {
        NSLog(@"Error didUpdateValueForCharacteristic : %@",error);
    }
}
//扫描Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    for (CBDescriptor * descriptor in characteristic.descriptors) {
        NSLog(@"descriptor: %@",descriptor);
        [peripheral readValueForDescriptor:descriptor];
    }
}
//获取Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"Descriptors UUID: %@ value: %@",descriptor.UUID,[NSString stringWithFormat:@"%@",descriptor.value]);
    NSLog(@"已经向外设%@的特征值%@写入数据",peripheral.name,_readCharacteristic);
}




@end
