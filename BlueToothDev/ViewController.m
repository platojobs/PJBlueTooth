//
//  ViewController.m
//  BlueToothDev
//
//  Created by Jobs Plato on 2020/11/21.
//

#import "ViewController.h"
#import<CoreBluetooth/CoreBluetooth.h>
@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic,strong)CBCentralManager *centralManager;
@property(nonatomic,strong)NSMutableArray *peripherals;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIButton*bluetooth=[UIButton buttonWithType:UIButtonTypeCustom];
    bluetooth.frame=CGRectMake(100, 0, self.view.bounds.size.width, 50);
    bluetooth.backgroundColor=[UIColor redColor];
    [bluetooth addTarget:self action:@selector(blconnect) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bluetooth];


}
#pragma mark==blconnect
-(void)blconnect{
    
    
    
}

#pragma mark==CBCentralManagerDelegate

// 1.4  必须实现的： //主设备状态改变的委托，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
                   case CBManagerStateUnknown:
                       NSLog(@">>>CBCentralManagerStateUnknown");
                       break;
                   case CBManagerStateResetting:
                       NSLog(@">>>CBCentralManagerStateResetting");
                       break;
                   case CBManagerStateUnsupported:
                       NSLog(@">>>CBCentralManagerStateUnsupported");
                       break;
                   case CBManagerStateUnauthorized:
                       NSLog(@"CBCentralManagerStateUnauthorized");
                       break;
                   case CBManagerStatePoweredOff:
                       NSLog(@"CBCentralManagerStatePoweredOff");
                       break;
                   case CBManagerStatePoweredOn:
         { NSLog(@"CBCentralManagerStatePoweredOn");
           
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey,
                                            nil];
            //第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
            //第二个参数可以添加一些option,来增加精确的查找范围
             [self.centralManager scanForPeripheralsWithServices:nil options:options];
         }
                       break;
            
                  default:
                  break;
            
            
    };
    
    
    
}
//其他选择实现的委托中比较重要的：找到外设的委托
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSLog(@"当扫描到设备:%@",peripheral.name);
           //接下来可以连接设备
    //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
    //这里自己去设置下连接规则，我设置的是P开头的设备
        if ([peripheral.name hasPrefix:@"P"]){
            
            //找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
            [self.peripherals addObject:peripheral];
                                //连接设备
            [self.centralManager connectPeripheral:peripheral options:nil];

        }
}
  //1.5 连接外设成功的委托
 - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
     
     NSLog(@"连接到名称为（%@）的设备-成功",peripheral.name);
     [peripheral setDelegate:self];
 }
//外设连接失败的委托
 - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
     
     NSLog(@"连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
     
 }
//断开外设的委托
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    NSLog(@"外设连接断开连接 %@ \n", [peripheral name]);
}
 

#pragma mark==CBPeripheralDelegate

//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
            //  NSLog(@"扫描到服务：%@",peripheral.services);
            if (error)
            {
                NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
                return;
            }

            for (CBService *service in peripheral.services) {
                  NSLog(@"%@",service.UUID);
//扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
                  [peripheral discoverCharacteristics:nil forService:service];
    }

}


// ==========获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值============//
//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
         if (error)
         {
             NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
             return;
         }

         for (CBCharacteristic *characteristic in service.characteristics)
         {
             NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
         }

         //获取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
         for (CBCharacteristic *characteristic in service.characteristics){
             {
                 [peripheral readValueForCharacteristic:characteristic];
             }
         }

         //搜索Characteristic的Descriptors，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
         for (CBCharacteristic *characteristic in service.characteristics){
             [peripheral discoverDescriptorsForCharacteristic:characteristic];
         }


}

//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
        //打印出characteristic的UUID和值
        //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
        NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);

   
}

    //搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

        //打印出Characteristic和他的Descriptors
         NSLog(@"characteristic uuid:%@",characteristic.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"Descriptor uuid:%@",d.UUID);
        }

   
}
    
//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
        //打印出DescriptorsUUID 和value
        //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
        NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
    
}

//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
                characteristic:(CBCharacteristic *)characteristic
                         value:(NSData *)value{

        //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
        /*
         typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
         CBCharacteristicPropertyBroadcast                                              = 0x01,
         CBCharacteristicPropertyRead                                                   = 0x02,
         CBCharacteristicPropertyWriteWithoutResponse                                   = 0x04,
         CBCharacteristicPropertyWrite                                                  = 0x08,
         CBCharacteristicPropertyNotify                                                 = 0x10,
         CBCharacteristicPropertyIndicate                                               = 0x20,
         CBCharacteristicPropertyAuthenticatedSignedWrites                              = 0x40,
         CBCharacteristicPropertyExtendedProperties                                     = 0x80,
         CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
         CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x200
         };

         */
        NSLog(@"%lu", (unsigned long)characteristic.properties);

        //只有 characteristic.properties 有write的权限才可以写
        if(characteristic.properties & CBCharacteristicPropertyWrite){
            /*
                最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
            */
            [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }else{
            NSLog(@"该字段不能写！");
        }
    }
//设置订阅通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
                characteristic:(CBCharacteristic *)characteristic{
        //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];

    }

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                 characteristic:(CBCharacteristic *)characteristic{

         [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                     peripheral:(CBPeripheral *)peripheral{
        //停止扫描
        [centralManager stopScan];
        //断开连接
        [centralManager cancelPeripheralConnection:peripheral];
}




#pragma mark== setter or getter



-(CBCentralManager*)centralManager{
    if (!_centralManager) {
        //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    return  _centralManager;
}


-(NSMutableArray*)peripherals{
    
    if (!_peripherals) {
        _peripherals=[NSMutableArray new];
    }
    return  _peripherals;
    
}

@end
