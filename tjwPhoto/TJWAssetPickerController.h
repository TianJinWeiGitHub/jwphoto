//
//  TJWAssetPickerController.m
//  TJWAssetPickerControllerDemo
//
//  Created by jinwei on 15-04-18.
//  Copyright (c) 2015年 weimi. All rights reserved.
//



#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHAsset.h>
#import <Photos/PHCollection.h>
#import <Photos/PHImageManager.h>
#import <Photos/PHFetchOptions.h>

#pragma mark - TJWAssetPickerController

@protocol TJWAssetPickerControllerDelegate;

@interface TJWAssetPickerController : UINavigationController

@property (nonatomic, weak) id <UINavigationControllerDelegate, TJWAssetPickerControllerDelegate> TJWdelegate;


/** 8.0之前使用assetsFilter,之后使用assetCollections*/
@property (nonatomic, strong) ALAssetsFilter *assetsFilter;
@property (nonatomic, strong) PHFetchResult<PHAssetCollection *> *assetCollections;


@property (nonatomic, copy, readonly) NSArray *indexPathsForSelectedItems;

@property (nonatomic, assign) NSInteger maximumNumberOfSelection;
@property (nonatomic, assign) NSInteger minimumNumberOfSelection;

@property (nonatomic, strong) NSPredicate *selectionFilter;

@property (nonatomic, assign) BOOL showCancelButton;

+ (UIImage*)createImageWithColor:(UIColor*)color;


@end

@protocol TJWAssetPickerControllerDelegate <NSObject>


@optional

/** 当kSystemEightAfterVerson 为YES  assets 存储的是 phaset 否则是alasset*/
-(void)assetPickerController:(TJWAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets;


-(void)assetPickerControllerDidCancel:(TJWAssetPickerController *)picker;


@end

#pragma mark - TJWAssetViewController

@interface TJWAssetViewController : UITableViewController

@property ( nonatomic,  strong)     ALAssetsGroup *assetsGroup;

@property ( nonatomic,  strong)     PHAssetCollection * phassetsGroup;

@property ( nonatomic,  strong)     NSMutableArray *indexPathsForSelectedItems;

@property ( nonatomic,  assign)     NSInteger number;

@property ( nonatomic,  copy )      NSString *naviationTitle;

@end


#pragma mark - TJWTapAssetView

@protocol TJWTapAssetViewDelegate <NSObject>

-(void)touchSelect:(BOOL)select;
-(BOOL)shouldTap;

@end

@interface TJWTapAssetView : UIView

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, weak) id<TJWTapAssetViewDelegate> delegate;

@end

#pragma mark - TJWAssetView

@protocol TJWAssetViewDelegate <NSObject>

-(BOOL)shouldSelectAsset:(NSObject*)assetobject;

-(void)tapSelectHandle:(BOOL)select asset:(NSObject*)assetobject;


@end

@interface TJWAssetView : UIView

- (void)bind:(ALAsset *)asset selectionFilter:(NSPredicate*)selectionFilter isSeleced:(BOOL)isSeleced;

- (void)bindphaset:(PHAsset *)asset selectionFilter:(NSPredicate*)selectionFilter isSeleced:(BOOL)isSeleced;

@end

#pragma mark - TJWAssetViewCell

@protocol TJWAssetViewCellDelegate;

@interface TJWAssetViewCell : UITableViewCell

@property(nonatomic,weak)id<TJWAssetViewCellDelegate> delegate;

- (void)bind:(NSArray *)assets selectionFilter:(NSPredicate*)selectionFilter minimumInteritemSpacing:(float)minimumInteritemSpacing minimumLineSpacing:(float)minimumLineSpacing columns:(int)columns assetViewX:(float)assetViewX;

- (void)bindphaset:(NSArray<PHAsset *> *)assets selectionFilter:(NSPredicate*)selectionFilter minimumInteritemSpacing:(float)minimumInteritemSpacing minimumLineSpacing:(float)minimumLineSpacing columns:(int)columns assetViewX:(float)assetViewX;


@end

@protocol TJWAssetViewCellDelegate <NSObject>

- (BOOL)shouldSelectAsset:(NSObject*)asset;
- (void)didSelectAsset:(NSObject*)asset;
- (void)didDeselectAsset:(NSObject*)asset;

@end

#pragma mark - TJWAssetGroupViewCell

@interface TJWAssetGroupViewCell : UITableViewCell

/** 8.0以前用这个 以后改成第二个*/
- (void)bind:(ALAssetsGroup *)assetsGroup;

- (void)bindcolection:(PHAssetCollection *) assetCollection;


@end

#pragma mark - TJWAssetGroupViewController

@interface TJWAssetGroupViewController : UITableViewController

@end

