//
//  IntoMessageTableViewController.m
//  IntoYunSdkDemo
//
//  Created by hui he on 17/4/7.
//  Copyright © 2017年 hui he. All rights reserved.
//

#import "IntoMessageTableViewController.h"
#import "IntoYunSDK.h"
#import "MJExtension.h"
#import "MBProgressHUD.h"
#import "MBProgressHUD+IntoYun.h"
#import "IntoMessageCell.h"

@interface IntoMessageTableViewController ()

//消息数组
@property(nonatomic, strong) NSMutableArray *messageArray;
//选中message数据
@property(nonatomic, strong) NSDictionary *selectedMessage;

@end

@implementation IntoMessageTableViewController


- (NSMutableArray *)messageArray {
    if (!_messageArray) {
        _messageArray = [NSMutableArray array];
    }
    return _messageArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = NSLocalizedString(@"message_title", nil);
    self.tabBarItem.badgeValue = @"2";
    self.tableView.tableFooterView = [[UIView alloc] init];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
    [self loadMessageData];
}

- (void)loadMessageData {
    IntoWeakSelf;
    [IntoYunSDKManager getMessages:@"1"
                      successBlock:^(id responseObject) {
                          weakSelf.messageArray = [IntoMessageModel mj_objectArrayWithKeyValuesArray:responseObject];
                          [weakSelf.tableView reloadData];
                      }
                        errorBlock:^(NSInteger code, NSString *errorStr) {
                            [MBProgressHUD showError:errorStr];
                        }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IntoMessageCell *cell = [IntoMessageCell cellWithTable:tableView Style:UITableViewCellStyleDefault reuseIdentifier:@"messageCell"];

    // Configure the cell...
    cell.messageModel = self.messageArray[indexPath.row];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedMessage = self.messageArray[indexPath.row];
    NSLog(@"selected row: %ld", (long) indexPath.row);
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    IntoMessageModel *messageModel = self.messageArray[indexPath.row];
    IntoWeakSelf;

    UITableViewRowAction *action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [IntoYunSDKManager deleteMessageById:messageModel.ID
                                successBlock:^(id responseObject) {
                                    [weakSelf.messageArray removeObjectAtIndex:indexPath.row];
                                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                    [MBProgressHUD showSuccess:@"删除成功"];
                                }
                                  errorBlock:^(NSInteger code, NSString *errorStr) {
                                      [MBProgressHUD showError:errorStr];
                                  }];
    }];

    return @[action1];
}


@end
