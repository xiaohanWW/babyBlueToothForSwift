//
//  BlueToothViewController.swift
//  Gofun
//
//  Created by 魏武 on 2017/3/3.
//  Copyright © 2017年 sqev. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import SnapKit
import CryptoSwift

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

class BlueToothEntity: NSObject {
    var peripheral: CBPeripheral?
    var RSSI: NSNumber?
    var advertisementData: Dictionary<String, Any>?
}

class PeripheralInfo: NSObject {
    var serviceUUID: CBUUID?
    var characteristics: [CBCharacteristic]?
}

class BlueToothViewController: UIViewController {
    
    var backImgV = UIImageView()
    var lightButton = UIButton()
    var redOrWriteBtn = UIButton()
    var writeZeroOne = UIButton()
    var writeZeroTwo = UIButton()

    
    let baby = BabyBluetooth.share()
    var peripheralDataArray = [BlueToothEntity]()
    var services = [PeripheralInfo]()
    var currentServiceCharacteristics = [CBCharacteristic]()
    var currPeripheral: CBPeripheral?
    let rhythm = BabyRhythm()
    //var sect = ["red", "write", "desc", "properties"]
    var readValueArray = [NSData]()
    var descriptors = [CBDescriptor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "蓝牙BiuBiuBiu~~~"
        self.view.backgroundColor = UIColor.white
        self.initView()
        // 设置蓝牙的delegate
        self.babyDelegate1()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        baby?.cancelAllPeripheralsConnection()
        _ = baby?.scanForPeripherals().begin()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        baby?.cancelScan()
    }
    
    func initView() {
        self.backImgV = UIImageView(frame: CGRect(x: (SCREEN_WIDTH-(SCREEN_WIDTH/2.5))/2, y: 140, width: SCREEN_WIDTH/2.5, height: SCREEN_WIDTH/2.5))
        self.backImgV.image = UIImage(named: "blueTooth")
        self.view.addSubview(self.backImgV)
        
        self.view.addSubview(self.lightButton)
        self.lightButton.snp.makeConstraints { (make) in
            make.top.equalTo(backImgV.snp.bottom).offset(20)
            make.centerX.equalTo(backImgV.snp.centerX)
        }
        
        self.lightButton.setTitle("连接", for: UIControlState.normal)
        self.lightButton.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.lightButton.addTarget(self, action: #selector(lightBtnAction), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(self.redOrWriteBtn)
        self.redOrWriteBtn.snp.makeConstraints { (make) in
            make.top.equalTo(lightButton.snp.bottom).offset(20)
            make.centerX.equalTo(lightButton.snp.centerX)
        }
        self.redOrWriteBtn.setTitle("准备读写", for: UIControlState.normal)
        self.redOrWriteBtn.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.redOrWriteBtn.addTarget(self, action: #selector(redOrWriteBtnAction), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(self.writeZeroOne)
        self.writeZeroOne.snp.makeConstraints { (make) in
            make.top.equalTo(redOrWriteBtn.snp.bottom).offset(20)
            make.centerX.equalTo(redOrWriteBtn.snp.centerX)
        }
        self.writeZeroOne.setTitle("写0x01", for: UIControlState.normal)
        self.writeZeroOne.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.writeZeroOne.addTarget(self, action: #selector(writeZeroOneAction), for: UIControlEvents.touchUpInside)
        
        self.view.addSubview(self.writeZeroTwo)
        self.writeZeroTwo.snp.makeConstraints { (make) in
            make.top.equalTo(writeZeroOne.snp.bottom).offset(20)
            make.centerX.equalTo(writeZeroOne.snp.centerX)
        }
        self.writeZeroTwo.setTitle("写0x02", for: UIControlState.normal)
        self.writeZeroTwo.setTitleColor(UIColor.red, for: UIControlState.normal)
        self.writeZeroTwo.addTarget(self, action: #selector(writeZeroTwoAction), for: UIControlEvents.touchUpInside)
    }
    
    func setData(peripheral: CBPeripheral, advertisementData: Dictionary<String, Any>, RSSI: NSNumber) {
        
        var peripherals = [CBPeripheral]()
        for index in 0 ..< Int(peripheralDataArray.count) {
            if let peripheral_ = peripheralDataArray[index].peripheral {
                peripherals.append(peripheral_)
            }
        }
        
        if (!(peripherals.contains(peripheral))) {
            let item = BlueToothEntity()
            item.peripheral = peripheral
            item.RSSI = RSSI
            item.advertisementData = advertisementData
            peripheralDataArray.append(item)
        }

        for index in 0 ..< Int(peripheralDataArray.count) {
            print("======>>>>>>1")
            print(peripheralDataArray[index].peripheral ?? "1")
            print("======>>>>>>2")
            print(peripheralDataArray[index].RSSI ?? "2")
            print("======>>>>>>3")
            print(peripheralDataArray[index].advertisementData ?? "3")
        }
    }
    
    /**
     进行第一步: 搜索到周围所有的蓝牙设备
     */
    func babyDelegate1() {
        baby?.setBlockOnCentralManagerDidUpdateState({ (centeral) in // CBManagerState
            if (centeral?.state.rawValue == CBCentralManagerState.poweredOn.rawValue) {
                print("设备打开成功,开始扫描设备")
            }
        })
        //let a:
        //设置扫描到设备的委托 1
        baby?.setBlockOnDiscoverToPeripherals({ [unowned self](central, peripheral, advertisementData, RSSI) in
            if let peripheralName = peripheral?.name {
                print(peripheralName)
                if (peripheralName.hasPrefix("iPhone")) {
                    print("搜索到了设备: \(peripheralName)")
                    self.setData(peripheral: peripheral!, advertisementData: advertisementData as! Dictionary<String, Any>, RSSI: RSSI!)
//                    self.baby?.cancelScan()
                }
            }
        })
        
        //设置发现设service的Characteristics的委托 2
        baby?.setBlockOnDiscoverCharacteristics({ (peripheral, service, error) in
            if let service_ = service {
                print("service name:\(service_.uuid)")
                if let service_characteristics = service_.characteristics {
                    //var characteristic: CBCharacteristic?
                    for characteristic in service_characteristics {
                        print("charateristic name is \(characteristic.uuid)")
                    }
                }
            }
        })
        
        //设置读取characteristics的委托 3
        baby?.setBlockOnReadValueForCharacteristic({ (peripheral, characteristic, error) in
            if let characteristic_ = characteristic {
                print("characteristic name is \(characteristic_.uuid),and its value is \(String(describing: characteristic_.value))")
            }
        })
        
        //设置发现characteristics的descriptors的委托 4
        baby?.setBlockOnDiscoverDescriptorsForCharacteristic({ (peripheral, characteristic, error) in
            if let characteristic_ = characteristic {
                print("characteristic name: \(characteristic_.service.uuid)")
            }
            if let descriptors_ = characteristic?.descriptors {
                for descriptor in descriptors_ {
                    print("descriptor name is:\(descriptor.uuid)")
                }
            }
        })
        
        //设置读取Descriptor的委托 5
        baby?.setBlockOnReadValueForDescriptors({ (peripheral, descriptor, error) in
            if let descriptor_ = descriptor {
                print("descriptor name is: \(descriptor_.characteristic.uuid) and its value is: \(String(describing: descriptor_.value))")
            }
        })

        //设置查找设备的过滤器 6
        baby?.setFilterOnDiscoverPeripherals({ (peripheralName, advertisementData, RSSI) -> Bool in
            if let peripheralName_ = peripheralName {
                print(peripheralName_)
                //最常用的场景是查找某一个前缀开头的设备
                if (peripheralName_.hasPrefix("iPhone")) {
                    return true
                }
            }
            return false
        })
        
        //babyBluettooth cancelAllPeripheralsConnectionBlock 方法调用后的回调 7
        baby?.setBlockOnCancelAllPeripheralsConnectionBlock({ (centralManager) in
            print("cancelAllPeripheralsConnectionBlock 方法调用后的回调")
        })
        
        //babyBluettooth cancelScan方法调用后的回调 8
        baby?.setBlockOnCancelScanBlock({ (centralManager) in
            print("cancelScan方法调用后的回调")
        })
        
        let scanForPeripheralsWithOptions = [CBCentralManagerScanOptionAllowDuplicatesKey:true]
        // 连接设备 9
        baby?.setBabyOptionsWithScanForPeripheralsWithOptions(scanForPeripheralsWithOptions, connectPeripheralWithOptions: nil, scanForPeripheralsWithServices: nil, discoverWithServices: nil, discoverWithCharacteristics: nil)
    }
    
    

    
    /// 点击开启第二步
    func lightBtnAction() {
        self.baby?.cancelScan()
//        _ = self.baby?.scanForPeripherals()
        self.babyDelegate2()
        self.loadData()
    }
    
    /// 点击开启第三步
    func redOrWriteBtnAction() {
        self.babyDelegate3()
        self.currPeripheral = peripheralDataArray[0].peripheral
        let x = peripheralDataArray[0].peripheral // 我这里是写死的 我测试的蓝牙设备
        let y = self.currentServiceCharacteristics[0] // 我这里是写死的 我测试的蓝牙设备的第0个characteristic
        let cc = baby?.channel("CharacteristicView").characteristicDetails() // 读取服务
        let _ = cc!(x,y)
    }
    
    /// 点击写入01
    func writeZeroOneAction() {
        var b = 0x01
        let data = NSData(bytes: &b, length: MemoryLayout.size(ofValue: b))
        self.currPeripheral?.writeValue(data as Data, for: (self.currentServiceCharacteristics[0]), type: CBCharacteristicWriteType.withResponse)
        print("写了\(b)")
    }
    /// 点击写入02
    func writeZeroTwoAction() {
        var b = 0x02
        let data = NSData(bytes: &b, length: MemoryLayout.size(ofValue: b))
        self.currPeripheral?.writeValue(data as Data, for: (self.currentServiceCharacteristics[0]), type: CBCharacteristicWriteType.withResponse)
        print("写了\(b)")
    }
    
    /**
     进行第二步, 读取某个设备的某条service的所有信息
     */
    func babyDelegate2() {
        
        //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调 1
        baby?.setBlockOnConnectedAtChannel("peripheralView", block: { (central, peripheral) in
            if let peripheralName = peripheral?.name {
                print("设备\(peripheralName)连接成功!!!")
            }
        })
        
        //设置设备连接失败的委托 2
        baby?.setBlockOnFailToConnectAtChannel("peripheralView", block: { (central, peripheral, error) in
            if let peripheralName = peripheral?.name {
                print("设备\(peripheralName)连接失败!!!")
            }
        })
        
        //设置设备断开连接的委托 3
        baby?.setBlockOnDisconnectAtChannel("peripheralView", block: { (central, peripheral, error) in
            if let peripheralName = peripheral?.name {
                print("设备\(peripheralName)连接断开!!!")
            }
        })
        
        //设置发现设备的Services的委托 4
        baby?.setBlockOnDiscoverServicesAtChannel("peripheralView", block: { [unowned self] (peripheral, error) in
            if let service_ = peripheral?.services {
                for mService in service_ {
                    self.setData2(service: mService)
                }
            }
            // 开启计时
            self.rhythm.beats()
        })
        
        //设置发现设service的Characteristics的委托 5
        baby?.setBlockOnDiscoverCharacteristicsAtChannel("peripheralView", block: { (peripheral, service, error) in
            if let service_ = service {
                print("service name:\(service_.uuid)")
                if (service_.uuid.uuidString == "EC5F093D-D259-4626-B909-A830CFCFB5E2") { // 这里是 我写死的一个调试的蓝牙设备的service uuid 可以自己替换
                    self.setData3(service: service_)
                }
            }
        })
        
        //设置读取characteristics的委托 6
        baby?.setBlockOnReadValueForCharacteristicAtChannel("peripheralView", block: { (peripheral, characteristics, error) in
            
            if characteristics != nil && characteristics!.value != nil {
                print("characteristic6 name is :\(String(describing: characteristics?.uuid)) and its value is: \(characteristics!.value!.bytes.toHexString())")
            }
            
/************************************* 注意这里注释了监听 ************************************************/
//            if (characteristics != nil) {
//                if (characteristics?.uuid.uuidString == "FFF0") {
//                    if (!(characteristics?.isNotifying)!) {
//                        peripheral?.setNotifyValue(true, for: characteristics!)
//                        print("开始监听\(characteristics)")
//                    }
//                }
//            }
        })
        
        //设置发现characteristics的descriptors的委托 7
        baby?.setBlockOnDiscoverDescriptorsForCharacteristicAtChannel("peripheralView", block: { (peripheral, characteristics, error) in
            if let characteristic_ = characteristics {
                print("characteristic name is :\(characteristic_.service.uuid)")
                if let descriptors_ = characteristic_.descriptors {
                    for descriptors in descriptors_ {
                        print("CBDescriptor name is:\(descriptors.uuid)")
                    }
                }
            }
        })
        
        //设置读取Descriptor的委托 8
        baby?.setBlockOnReadValueForDescriptorsAtChannel("peripheralView", block: { (peripheral, descriptor, error) in
            if let descriptors_ = descriptor {
                print("descriptor name is :\(descriptors_.uuid) and its value is: \(String(describing: descriptors_.value))")
            }
        })
        
        //读取rssi的委托 9
        baby?.setBlockOnDidReadRSSI({ (RSSI, error) in
            if let RSSI_ = RSSI {
                print("读取到RSSI:\(RSSI_)")
            }
        })
        
        //设置beats break委托 10
        rhythm.setBlockOnBeatsBreak { (bry) in
            print("setBlockOnBeatsBreak调用")
        }
        
        //设置beats over委托 11
        rhythm.setBlockOnBeatsOver { (bry) in
            print("setBlockOnBeatsOver调用")
        }
        
        //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
        let scanForPeripheralsWithOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        
        /*连接选项->
         CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
         CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
         CBConnectPeripheralOptionNotifyOnNotificationKey:
         当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
         */
        let connectOptions = [CBConnectPeripheralOptionNotifyOnConnectionKey: true, CBConnectPeripheralOptionNotifyOnDisconnectionKey: true, CBConnectPeripheralOptionNotifyOnNotificationKey: true]
        
        baby?.setBabyOptionsAtChannel("peripheralView", scanForPeripheralsWithOptions: scanForPeripheralsWithOptions, connectPeripheralWithOptions: connectOptions, scanForPeripheralsWithServices: nil, discoverWithServices: nil, discoverWithCharacteristics: nil)
    }
    
    func setData2(service: CBService) {
        print("搜索到服务: \(service.uuid.uuidString)")
        let info = PeripheralInfo()
        info.serviceUUID = service.uuid
        self.services.append(info)
    }
    
    func setData3(service: CBService) {
        if let characteristics_ = service.characteristics {
            self.currentServiceCharacteristics = characteristics_
        }
    }
    
    func loadData() {
        print("俺要开始连接设备...")
        if (self.peripheralDataArray.count > 0) {
            _ = baby?.having(self.peripheralDataArray[0].peripheral).and().channel("peripheralView").then().connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin()
        } else {
            print("没有搜索到您想链接的蓝牙")
        }
    }
    
    /**
     进行第三步-- 读写某个Characteristic
     */
    func babyDelegate3() {
        
        // 设置读取characteristics的委托  1
        baby?.setBlockOnReadValueForCharacteristicAtChannel("CharacteristicView", block: { (peripheral, characteristics, error) in
            print("CharacteristicView===>>> characteristic name: \(String(describing: characteristics?.uuid)) and value is : \(String(describing: characteristics?.value))")
        })
        
        //设置发现characteristics的descriptors的委托  2
        baby?.setBlockOnDiscoverDescriptorsForCharacteristicAtChannel("CharacteristicView", block: { (peripheral, characteristics, error) in
            print("CharacteristicView===>>>characteristic name: \(String(describing: characteristics?.service.uuid))")
            if (characteristics?.descriptors?.count != 0) {
                for d in (characteristics?.descriptors)! {
                    print("CharacteristicViewController CBDescriptor name is :\(d.uuid)")
                }
            }
        })
        
        //设置读取Descriptor的委托 3
        baby?.setBlockOnReadValueForDescriptorsAtChannel("CharacteristicView", block: {[unowned self] (peripheral, descriptor, error) in
            
            for i in 0..<self.descriptors.count {
                if (self.descriptors[i] == descriptor) {
                    print("我是委托3 --->>> 我找到对应的descriptor了")
                }
            }
            print("CharacteristicView Descriptor name:\(String(describing: descriptor?.characteristic.uuid)) value is:\(String(describing: descriptor?.value))")
        })
        
        //设置写数据成功的block    4
        baby?.setBlockOnDidWriteValueForCharacteristicAtChannel("CharacteristicView", block: { (characteristic, error) in
            print("setBlockOnDidWriteValueForCharacteristicAtChannel characteristic: \(String(describing: characteristic?.uuid)) and new value:\(String(describing: characteristic?.value))")
        })
        
        //设置通知状态改变的block    5
        baby?.setBlockOnDidUpdateNotificationStateForCharacteristicAtChannel("CharacteristicView", block: { (characteristic, error) in
            
            print("uid:\(String(describing: characteristic?.uuid)), isNotifying: \((characteristic?.isNotifying)! ? "on" : "off")")
        })
    }
}
