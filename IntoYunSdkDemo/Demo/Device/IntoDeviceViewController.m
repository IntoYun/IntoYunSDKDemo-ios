//
//  IntoDeviceViewController.m
//  IntoYunSDKDemo
//
//  Created by 梁惠源 on 16/8/15.
//  Copyright © 2016年 MOLMC. All rights reserved.
//

#import "IntoDeviceViewController.h"
#import "IntoYunSDK.h"
#import "DTKDropdownMenuView.h"
#import "IntoImlinkConfigViewController.h"
#import "IntoDeviceInfoViewController.h"
#import "IntoDeviceViewCell.h"
#import "IntoYunMQTTManager.h"
#import "IntoControlDeviceViewController.h"
#import "MBProgressHUD+IntoYun.h"
#import "MJExtension.h"
#import "IntoYunFMDBTool.h"
#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"

@interface IntoDeviceViewController () <IntoYunMQTTManagerDelegate, QRCodeReaderDelegate>
/** 设备数组 */
@property(nonatomic, strong) NSMutableArray *deviceArray;
/** 选中的设备数数据 */
@property(nonatomic, weak) DeviceModel *selectDevice;
/** datapoint */
@property(nonatomic, weak) NSArray *selectedDatapoints;

@end

@implementation IntoDeviceViewController


static NSString *const reuseIdentifier = @"deviceCell";

- (NSMutableArray *)deviceArray {
    if (!_deviceArray) {
        _deviceArray = [NSMutableArray array];
    }
    return _deviceArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigation];

    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.frame = self.view.bounds;

    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([IntoDeviceViewCell class]) bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.alwaysBounceVertical=YES;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self.userData setValue:[userDefaults valueForKey:@"IntoYunUid"] forKey:@"uid"];
    [self.userData setValue:[userDefaults valueForKey:@"IntoYunUserToken"] forKey:@"token"];

    [self subDevicesStatus];
    // 加载数据
    [self loadDeviceData];
    [self getProductData];
}


- (void)setNavigation {
    self.navigationItem.title = NSLocalizedString(@"device_title", nil);
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"back", nill) style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    //扫描
    UIBarButtonItem *rightMaxBt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(onClickScanButton)];
    //添加
    UIBarButtonItem *rightSharBt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onClickAddButton)];
    NSArray *buttonItem = @[rightSharBt, rightMaxBt];
    self.navigationItem.rightBarButtonItems = buttonItem;

}


- (void)onClickAddButton {
    [self performSegueWithIdentifier:@"configGuide" sender:nil];
}


- (void)onClickScanButton {
    if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
        static QRCodeReaderViewController *reader = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            reader = [[QRCodeReaderViewController alloc] initWithCancelButtonTitle:@"取消"];
        });
        reader.delegate = self;

        [self presentViewController:reader animated:YES completion:NULL];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"请允许访问相机" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

// 请求数据
- (void)loadDeviceData {
    IntoWeakSelf;
    [IntoYunSDKManager getDevices:^(id responseObject) {
                weakSelf.deviceArray = [DeviceModel mj_objectArrayWithKeyValuesArray:responseObject];
                [weakSelf.collectionView reloadData];
                [IntoYunFMDBTool saveDevices:responseObject];
                // 订阅 topic
                [weakSelf subDevicesStatus];

            }
                       errorBlock:^(NSInteger code, NSString *errorStr) {
                           [MBProgressHUD showError:errorStr];
                       }];
}

- (void)getProductData {
    [IntoYunSDKManager getProducts:^(id responseObject) {
                [IntoYunFMDBTool saveDatapoints:responseObject];
            }
                        errorBlock:^(NSInteger code, NSString *errorStr) {
                            [MBProgressHUD showError:errorStr];
                        }];
}

// 订阅
- (void)subDevicesStatus {
    for (DeviceModel *device in self.deviceArray) {
        [[IntoYunMQTTManager shareInstance] subscribeDeviceInfo:device.deviceId delegate:self];
    }
}

#pragma mark - Table view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.deviceArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IntoDeviceViewCell *cell = [IntoDeviceViewCell cellWithCollection:collectionView reuseIdentifier:reuseIdentifier cellForItemAtIndexPath:indexPath];

    // Configure the cell
    cell.deviceModel = self.deviceArray[indexPath.row];

    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    DeviceModel *deviceModel = self.deviceArray[indexPath.row];

    NSArray *datapoints = [IntoYunFMDBTool getDatapointListArray:deviceModel.pidImp];

    if (datapoints.count == 0) {
        [MBProgressHUD showError:NSLocalizedString(@"datapoint_null", nil)];
        return;
    }
    self.selectedDatapoints = datapoints;
    self.selectDevice = deviceModel;
    [self performSegueWithIdentifier:@"controlDevice" sender:nil];
}


//定义每个UICollectionView 的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((collectionView.frame.size.width / 2.0) - 5.0, 120);
}

//定义每个UICollectionView 的 margin
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 5, 0);
}


/**
 *   跳转之前的准备
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"deviceInfo"]) {
        IntoWeakSelf;
        IntoDeviceInfoViewController *deviceInfoVC = segue.destinationViewController;
        deviceInfoVC.deviceDic = [self.selectDevice mj_keyValues];
        deviceInfoVC.changeSuccess = ^{
            [weakSelf loadDeviceData];
        };
    } else if ([segue.identifier isEqualToString:@"controlDevice"]) {
        IntoControlDeviceViewController *controlDeviceVC = segue.destinationViewController;
        controlDeviceVC.deviceModel = self.selectDevice;
        controlDeviceVC.userData = self.userData;
        controlDeviceVC.datapointArray = self.selectedDatapoints;
    }
}


- (void)messageTopic:(NSString *)topic data:(NSData *)dic {
    NSArray *topicArray = [topic componentsSeparatedByString:@"/"];
    NSString *topicDeviceID = topicArray[2];
    NSMutableDictionary *result = [NSJSONSerialization JSONObjectWithData:dic options:NSJSONReadingMutableLeaves error:nil];
    BOOL status = NO;
    if ([[result valueForKey:@"online"] isKindOfClass:[NSString class]]) {
        if ([[result valueForKey:@"online"] isEqualToString:@"false"]) {
            status = NO;
        } else {
            status = YES;
        }
    } else {
        status = [result valueForKey:@"online"];
    }
    for (DeviceModel *device in self.deviceArray) {
        if ([device.deviceId isEqualToString:topicDeviceID]) {
            device.status = status;
            [self.collectionView reloadData];
            break;
        }
    }
}


- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result {
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *emailRegex = @"^[A-Za-z0-9]{16,24}";
        NSPredicate *numberTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if ([numberTest evaluateWithObject:result]) {
            [IntoYunSDKManager bindDevice:result
                             successBlock:^(id responseObject) {
                                 [MBProgressHUD showSuccess:NSLocalizedString(@"bind_success", nil)];
                             }
                               errorBlock:^(NSInteger code, NSString *errorStr) {
                                   [MBProgressHUD showError:errorStr];
                               }];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"qrcode_error", nil) message:result delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
