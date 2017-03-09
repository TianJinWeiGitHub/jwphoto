//
//  TJWAssetPickerController.m
//  TJWAssetPickerControllerDemo
//
//  Created by jinwei on 15-04-18.
//  Copyright (c) 2015年 weimi. All rights reserved.
//



#import "TJWAssetPickerController.h"

#define kSystemEightAfterVerson [[UIDevice currentDevice].systemVersion doubleValue] >= 8.0

#define kPhotoSpace             3.0f

#define kPhptocolumns           4

#define kThumbnailLength    ([UIScreen mainScreen].bounds.size.width-(kPhptocolumns+1)*kPhotoSpace)/kPhptocolumns

#define kThumbnailSize      CGSizeMake(kThumbnailLength, kThumbnailLength)

#define kPopoverContentSize CGSizeMake(320, 480)

#pragma mark -

@interface NSDate (TimeInterval) 

+ (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval;

@end

@implementation NSDate (TimeInterval)

+ (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *date1 = [[NSDate alloc] init];
    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:date1];
    
    unsigned int unitFlags = 0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    unitFlags = NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit |
    NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
#pragma clang diagnostic pop
    
    return [calendar components:unitFlags
                       fromDate:date1
                         toDate:date2
                        options:0];
}

+ (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval
{
    NSDateComponents *components = [self.class componetsWithTimeInterval:timeInterval];
    NSInteger roundedSeconds = lround(timeInterval - (components.hour * 60) - (components.minute * 60 * 60));
    
    if (components.hour > 0)
    {
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)components.hour, (long)components.minute, (long)roundedSeconds];
    }
    
    else
    {
        return [NSString stringWithFormat:@"%ld:%02ld", (long)components.minute, (long)roundedSeconds];
    }
}

@end

#pragma mark - TJWAssetPickerController

@interface TJWAssetPickerController ()

@property (nonatomic, copy) NSArray *indexPathsForSelectedItems;

@end


#pragma mark - TJWTapAssetView

@interface TJWTapAssetView ()

@property(nonatomic,retain)UIImageView *selectView;

@end

@implementation TJWTapAssetView


static UIImage *checkedNoIcon;

static UIImage *checkedIcon;
static UIColor *selectedColor;
static UIColor *disabledColor;

+ (void)initialize
{
    checkedIcon     = [UIImage imageNamed:@"icon_tjwphoto_selected@2x.png"];
    checkedNoIcon     = [UIImage imageNamed:@"icon_tjwphoto_unselected@2x.png"];
    selectedColor   = [UIColor colorWithWhite:0.7 alpha:0.4];
    disabledColor   = [UIColor colorWithWhite:1 alpha:1.0];
}

-(id)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        //设置勾勾的位置
        _selectView=[[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width-30, 5, 25, 25)];
        [self addSubview:_selectView];
    }
    return self;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_disabled) {
        return;
    }
    
    if (_delegate!=nil&&[_delegate respondsToSelector:@selector(shouldTap)]) {
        if (![_delegate shouldTap]&&!_selected) {
            return;
        }
    }

    if ((_selected=!_selected)) {
        self.backgroundColor = selectedColor;
        [_selectView setImage:checkedIcon];
    }
    else{
        self.backgroundColor=[UIColor clearColor];
        //[_selectView setImage:nil];
        [_selectView setImage:checkedNoIcon];
    }
    if (_delegate!=nil&&[_delegate respondsToSelector:@selector(touchSelect:)]) {
        [_delegate touchSelect:_selected];
    }
}

-(void)setDisabled:(BOOL)disabled{
    _disabled = disabled;
    if (_disabled) {
        self.backgroundColor = disabledColor;
    }
    else{
        self.backgroundColor=[UIColor clearColor];
    }
}

-(void)setSelected:(BOOL)selected{
    if (_disabled) {
        self.backgroundColor=disabledColor;
        [_selectView setImage:nil];
        return;
    }

    _selected=selected;
    if (_selected) {
        self.backgroundColor=selectedColor;
        [_selectView setImage:checkedIcon];
    }
    else{
        self.backgroundColor=[UIColor clearColor];
        [_selectView setImage:checkedNoIcon];
    }
}

@end

#pragma mark - TJWAssetView

@interface TJWAssetView ()<TJWTapAssetViewDelegate>

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) PHAsset *phasset;

@property (nonatomic, weak) id<TJWAssetViewDelegate> delegate;

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) TJWTapAssetView *tapAssetView;

@end

@implementation TJWAssetView

static UIFont *titleFont = nil;

static CGFloat titleHeight;
static UIColor *titleColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:12];
    titleHeight     = 20.0f;
    titleColor      = [UIColor whiteColor];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                     = YES;
        self.isAccessibilityElement     = YES;
        self.accessibilityTraits        = UIAccessibilityTraitImage;
        
        _imageView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kThumbnailSize.width, kThumbnailSize.height)];
        [self addSubview:_imageView];
        
    
        
        _tapAssetView=[[TJWTapAssetView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _tapAssetView.delegate=self;
        [self addSubview:_tapAssetView];
    }
    
    return self;
}

- (void)bind:(ALAsset *)asset selectionFilter:(NSPredicate*)selectionFilter isSeleced:(BOOL)isSeleced
{
    self.asset=asset;
    
    [_imageView setImage:[UIImage imageWithCGImage:asset.thumbnail]];
    
    _tapAssetView.disabled=! [selectionFilter evaluateWithObject:asset];
    
    _tapAssetView.selected=isSeleced;
}

- (void)bindphaset:(PHAsset *)asset selectionFilter:(NSPredicate*)selectionFilter isSeleced:(BOOL)isSeleced
{
    self.phasset    =   asset;
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:kThumbnailSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        _imageView.image        =  result;
        
    }];

    _tapAssetView.disabled = ![selectionFilter evaluateWithObject:asset];
    
    _tapAssetView.selected = isSeleced;
}

#pragma mark - TJWTapAssetView Delegate

-(BOOL)shouldTap{
    if (_delegate!=nil && [_delegate respondsToSelector:@selector(shouldSelectAsset:)]) {
        
        if (kSystemEightAfterVerson) {
            
            return [_delegate shouldSelectAsset:_phasset];

        }else{
            return [_delegate shouldSelectAsset:_asset];

        }
        
    }
    return YES;
}

-(void)touchSelect:(BOOL)select{
    if (_delegate!=nil&&[_delegate respondsToSelector:@selector(tapSelectHandle:asset:)]) {
        
        if (kSystemEightAfterVerson) {
            [_delegate tapSelectHandle:select asset:_phasset];

        }else{
            [_delegate tapSelectHandle:select asset:_asset];
        }
        
    }
}

@end

#pragma mark - TJWAssetViewCell

@interface TJWAssetViewCell ()<TJWAssetViewDelegate>

@end

@class TJWAssetViewController;

@implementation TJWAssetViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if ([super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    return self;
}

- (void)bindphaset:(NSArray<PHAsset *> *)assets selectionFilter:(NSPredicate*)selectionFilter minimumInteritemSpacing:(float)minimumInteritemSpacing minimumLineSpacing:(float)minimumLineSpacing columns:(int)columns assetViewX:(float)assetViewX
{
    if (self.contentView.subviews.count< assets.count) {
        for (int i=0; i<assets.count; i++) {
            if (i>((NSInteger)self.contentView.subviews.count-1)) {
                TJWAssetView *assetView=[[TJWAssetView alloc] initWithFrame:CGRectMake(assetViewX+(kThumbnailSize.width+minimumInteritemSpacing)*i, minimumLineSpacing-1, kThumbnailSize.width, kThumbnailSize.height)];
                [assetView bindphaset:assets[i] selectionFilter:selectionFilter isSeleced:[((TJWAssetViewController*)_delegate).indexPathsForSelectedItems containsObject:assets[i]]];
                assetView.delegate=self;
                [self.contentView addSubview:assetView];
            }
            else{
                ((TJWAssetView*)self.contentView.subviews[i]).frame=CGRectMake(assetViewX+(kThumbnailSize.width+minimumInteritemSpacing)*(i), minimumLineSpacing-1, kThumbnailSize.width, kThumbnailSize.height);
                [(TJWAssetView*)self.contentView.subviews[i] bindphaset:assets[i] selectionFilter:selectionFilter isSeleced:[((TJWAssetViewController*)_delegate).indexPathsForSelectedItems containsObject:assets[i]]];
            }
            
        }
        
    }
    else{
        for (NSInteger i = self.contentView.subviews.count;  i > 0; i--) {
            if (i > assets.count) {
                
                [((TJWAssetView*)self.contentView.subviews[i-1]) removeFromSuperview];
            }
            else{
                ((TJWAssetView*)self.contentView.subviews[i-1]).frame=CGRectMake(assetViewX+(kThumbnailSize.width+minimumInteritemSpacing)*(i-1), minimumLineSpacing-1, kThumbnailSize.width, kThumbnailSize.height);
                [(TJWAssetView*)self.contentView.subviews[i-1] bindphaset:assets[i-1] selectionFilter:selectionFilter isSeleced:[((TJWAssetViewController*)_delegate).indexPathsForSelectedItems containsObject:assets[i-1]]];
            }
        }
    }

}

- (void)bind:(NSArray *)assets selectionFilter:(NSPredicate*)selectionFilter minimumInteritemSpacing:(float)minimumInteritemSpacing minimumLineSpacing:(float)minimumLineSpacing columns:(int)columns assetViewX:(float)assetViewX{
    
    if (self.contentView.subviews.count< assets.count) {
        for (int i=0; i<assets.count; i++) {
            if (i>((NSInteger)self.contentView.subviews.count-1)) {
                TJWAssetView *assetView=[[TJWAssetView alloc] initWithFrame:CGRectMake(assetViewX+(kThumbnailSize.width+minimumInteritemSpacing)*i, minimumLineSpacing-1, kThumbnailSize.width, kThumbnailSize.height)];
                [assetView bind:assets[i] selectionFilter:selectionFilter isSeleced:[((TJWAssetViewController*)_delegate).indexPathsForSelectedItems containsObject:assets[i]]];
                assetView.delegate=self;
                [self.contentView addSubview:assetView];
            }
            else{
                ((TJWAssetView*)self.contentView.subviews[i]).frame=CGRectMake(assetViewX+(kThumbnailSize.width+minimumInteritemSpacing)*(i), minimumLineSpacing-1, kThumbnailSize.width, kThumbnailSize.height);
                [(TJWAssetView*)self.contentView.subviews[i] bind:assets[i] selectionFilter:selectionFilter isSeleced:[((TJWAssetViewController*)_delegate).indexPathsForSelectedItems containsObject:assets[i]]];
            }

        }
        
    }
    else{
        for (NSInteger i = self.contentView.subviews.count;  i > 0; i--) {
            if (i > assets.count) {
                
                [((TJWAssetView*)self.contentView.subviews[i-1]) removeFromSuperview];
            }
            else{
                ((TJWAssetView*)self.contentView.subviews[i-1]).frame=CGRectMake(assetViewX+(kThumbnailSize.width+minimumInteritemSpacing)*(i-1), minimumLineSpacing-1, kThumbnailSize.width, kThumbnailSize.height);
                [(TJWAssetView*)self.contentView.subviews[i-1] bind:assets[i-1] selectionFilter:selectionFilter isSeleced:[((TJWAssetViewController*)_delegate).indexPathsForSelectedItems containsObject:assets[i-1]]];
            }
        }
    }
}

#pragma mark - TJWAssetView Delegate

-(BOOL)shouldSelectAsset:(NSObject*)assetobject{
    if (_delegate!=nil&&[_delegate respondsToSelector:@selector(shouldSelectAsset:)]) {
        if ([assetobject isKindOfClass:[PHAsset class]]) {
            return [_delegate shouldSelectAsset:assetobject];
        }
    }
    return YES;
}

-(void)tapSelectHandle:(BOOL)select asset:(NSObject*)assetobject{
    if (select) {
        if (_delegate!=nil&&[_delegate respondsToSelector:@selector(didSelectAsset:)]) {
            [_delegate didSelectAsset:assetobject];
        }
    }
    else{
        if (_delegate!=nil&&[_delegate respondsToSelector:@selector(didDeselectAsset:)]) {
            [_delegate didDeselectAsset:assetobject];
        }
    }
}

@end

#pragma mark - TJWAssetViewController

@interface TJWAssetViewController ()<TJWAssetViewCellDelegate>{
    
    BOOL unFirst;
    
    int rows;
    
}

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *phassets;


@property (nonatomic, assign) NSInteger numberOfPhotos;
@property (nonatomic, assign) NSInteger numberOfVideos;



@end

#define kAssetViewCellIdentifier           @"AssetViewCellIdentifier"

@implementation TJWAssetViewController

- (id)init
{
    _indexPathsForSelectedItems =   [[NSMutableArray alloc] init];
    
    self.tableView.contentInset =   UIEdgeInsetsMake(5.0, 0, 0, 0);

    if (self = [super init])
    {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!unFirst) {
        
        [self setupAssets];
        
        unFirst=YES;
    }
}


#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
   
  
    self.tableView.contentInset=UIEdgeInsetsMake(5.0, 0, 0, 0);
    
    [self.tableView reloadData];
}

#pragma mark - Setup

- (void)setupViews
{
    self.tableView.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"完成", nil)style:UIBarButtonItemStylePlain target:self action:@selector(finishPickingAssets:)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}


- (void)setupAssets
{
    if (kSystemEightAfterVerson) {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:self.phassetsGroup options:nil];
        self.phassets = [[NSMutableArray alloc]init];
        
        self.numberOfPhotos = 0;
        self.numberOfVideos = 0;
        
        for (PHAsset *aset in assets) {
            
            if (aset.mediaType == PHAssetMediaTypeImage) {
                
                self.numberOfPhotos++;
                
            }else if (aset.mediaType == PHAssetMediaTypeVideo){
                
                self.numberOfVideos++;
            }
            
            [self.phassets addObject:aset];
        }
        
        rows = ceil(self.phassets.count*1.0/kPhptocolumns);
                    
        [self.tableView reloadData];
        
    }else{
        if (!self.assets)
            self.assets = [[NSMutableArray alloc] init];
        else
            [self.assets removeAllObjects];
        
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        self.numberOfPhotos = 0;
        self.numberOfVideos = 0;
        
        ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
            
            if (asset)
            {
                [self.assets addObject:asset];
                
                NSString *type = [asset valueForProperty:ALAssetPropertyType];
                
                if ([type isEqual:ALAssetTypePhoto])
                    self.numberOfPhotos ++;
                if ([type isEqual:ALAssetTypeVideo])
                    self.numberOfVideos ++;
            }
            
            else if (self.assets.count > 0)
            {
                rows = ceil(self.phassets.count*1.0/kPhptocolumns);

                [self.tableView reloadData];
                
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:ceil(self.assets.count*1.0/kPhptocolumns)  inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        };
        
        [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
        
    }
   
}

#pragma mark - UITableView DataSource
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row  == rows) {
        UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"cellFooter"];
        
        if (cell==nil) {
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellFooter"];
            cell.textLabel.font=[UIFont systemFontOfSize:16.0];
            cell.textLabel.backgroundColor  =   [UIColor clearColor];
            cell.textLabel.textAlignment    =   NSTextAlignmentCenter;
            cell.textLabel.textColor        =   [UIColor blackColor];
            cell.backgroundColor            =   [UIColor clearColor];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        
        NSString *title;
        
        if (_numberOfVideos == 0)
            title = [NSString stringWithFormat:NSLocalizedString(@"共计 %ld 张照片", nil), (long)_numberOfPhotos];
        else if (_numberOfPhotos == 0)
            title = [NSString stringWithFormat:NSLocalizedString(@"共计 %ld 部视频", nil), (long)_numberOfVideos];
        else
            title = [NSString stringWithFormat:NSLocalizedString(@"共计 %ld 张照片, %ld 部视频", nil), (long)_numberOfPhotos, (long)_numberOfVideos];
        
        cell.textLabel.text=title;
        return cell;
    }
    
    
    
    static NSString *CellIdentifier = kAssetViewCellIdentifier;
    TJWAssetPickerController *picker = (TJWAssetPickerController *)self.navigationController;
    
    TJWAssetViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil) {
        
        cell=[[TJWAssetViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.delegate=self;

    
    if (kSystemEightAfterVerson) {
        
        NSMutableArray<PHAsset *> *tempAssets=[[NSMutableArray alloc] init];
        
        for (int i = 0; i< kPhptocolumns; i++) {
            if ((indexPath.row*kPhptocolumns+i)<self.phassets.count) {
                [tempAssets addObject:[self.phassets objectAtIndex:indexPath.row*kPhptocolumns+i]];
            }
        }
        
        [cell bindphaset:tempAssets selectionFilter:picker.selectionFilter minimumInteritemSpacing:kPhotoSpace minimumLineSpacing:kPhotoSpace columns:kPhptocolumns assetViewX:(self.tableView.frame.size.width-kThumbnailSize.width*tempAssets.count-kPhotoSpace*(tempAssets.count-1))/2];
    }else{
        
        NSMutableArray *tempAssets=[[NSMutableArray alloc] init];
        
        for (int i = 0; i< kPhptocolumns; i++) {
            
            if ((indexPath.row*kPhptocolumns+i)<self.assets.count) {
                
                [tempAssets addObject:[self.assets objectAtIndex:indexPath.row*kPhptocolumns+i]];
            }
        }

        [cell bind:tempAssets selectionFilter:picker.selectionFilter minimumInteritemSpacing:kPhotoSpace minimumLineSpacing:kPhotoSpace columns:kPhptocolumns assetViewX:(self.tableView.frame.size.width-kThumbnailSize.width*tempAssets.count-kPhotoSpace*(tempAssets.count-1))/2];
    }
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
   return rows+1;
}

#pragma mark - UITableView Delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row== rows+1) {
        return 44;
    }
    return kThumbnailSize.height+kPhotoSpace;
}


#pragma mark - TJWAssetViewCell Delegate

- (BOOL)shouldSelectAsset:(NSObject *)asset
{
    TJWAssetPickerController *vc = (TJWAssetPickerController *)self.navigationController;
    BOOL selectable = [vc.selectionFilter evaluateWithObject:asset];
    return (selectable && _indexPathsForSelectedItems.count < vc.maximumNumberOfSelection);
}

- (void)didSelectAsset:(NSObject *)asset
{
    [_indexPathsForSelectedItems addObject:asset];
    
    TJWAssetPickerController *vc = (TJWAssetPickerController *)self.navigationController;
    vc.indexPathsForSelectedItems = _indexPathsForSelectedItems;
    
    [self setTitleWithSelectedIndexPaths:_indexPathsForSelectedItems];
}

- (void)didDeselectAsset:(NSObject *)asset
{
    [_indexPathsForSelectedItems removeObject:asset];
    
    TJWAssetPickerController *vc = (TJWAssetPickerController *)self.navigationController;
    vc.indexPathsForSelectedItems = _indexPathsForSelectedItems;
    [self setTitleWithSelectedIndexPaths:_indexPathsForSelectedItems];
}


#pragma mark - Title

- (void)setTitleWithSelectedIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0)
    {
        self.navigationItem.title = self.naviationTitle;

        return;
    }
    
    BOOL photosSelected = NO;
    BOOL videoSelected  = NO;
    
    if (kSystemEightAfterVerson) {
        
        for (int i=0; i<indexPaths.count; i++) {
            PHAsset *asset = indexPaths[i];
            
            if (asset.mediaType == PHAssetMediaTypeImage)
                photosSelected  = YES;
            
            if (asset.mediaType == PHAssetMediaTypeVideo)
                videoSelected   = YES;
            
            if (photosSelected && videoSelected)
                break;
            
        }

    }else{
        for (int i=0; i<indexPaths.count; i++) {
            ALAsset *asset = indexPaths[i];
            
            if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto])
                photosSelected  = YES;
            
            if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
                videoSelected   = YES;
            
            if (photosSelected && videoSelected)
                break;
            
        }
        

    }
   
    
    
    
    self.number = indexPaths.count;

    NSString *format;
    
    if (photosSelected && videoSelected)
        format =  [NSString stringWithFormat:@"已选择 %ld 个项目",self.number];
    
    else if (photosSelected)
        format =  [NSString stringWithFormat:@"已选择 %ld 张照片",self.number];

    
    else if (videoSelected)
        format =  [NSString stringWithFormat:@"已选择 %ld 部视频",self.number];
    
    self.navigationItem.title = format;
}


#pragma mark - Actions

- (void)finishPickingAssets:(id)sender
{
    
    TJWAssetPickerController *picker = (TJWAssetPickerController *)self.navigationController;
    
    if ([picker.TJWdelegate respondsToSelector:@selector(assetPickerController:didFinishPickingAssets:)]){
       [ picker.TJWdelegate assetPickerController:picker didFinishPickingAssets:_indexPathsForSelectedItems];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}

@end

#pragma mark - TJWAssetGroupViewCell

@interface TJWAssetGroupViewCell ()
{
    UIImageView *leftImageView;
    UILabel     *groupLabel;
    UILabel     *desLabel;
}

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) PHAssetCollection *colection;

@end

@implementation TJWAssetGroupViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        leftImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 10, 70, 70)];
        leftImageView.contentMode = UIViewContentModeScaleAspectFill;
        leftImageView.clipsToBounds = YES;
        [self.contentView addSubview:leftImageView];
        
        groupLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 90/2-18, 200, 16)];
        groupLabel.textColor = [UIColor blackColor];
        groupLabel.font = [UIFont systemFontOfSize:16.0f];
        [self.contentView addSubview:groupLabel];
        
        desLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 90/2+2, 200, 16)];
        desLabel.textColor = [UIColor blackColor];
        desLabel.font = [UIFont systemFontOfSize:14.0f];
        [self.contentView addSubview:desLabel];
        
        self.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;

    }
    return self;
}

- (void)bindcolection:(PHAssetCollection *) assetCollection
{
    self.colection = assetCollection;
    
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    if (assets && assets.count >0) {
        
        PHAsset *oneSet = [assets firstObject];
        
        [[PHImageManager defaultManager] requestImageForAsset:oneSet targetSize:kThumbnailSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            leftImageView.image        =  result;
            leftImageView.contentMode = UIViewContentModeScaleAspectFill;

        }];
        desLabel.text   = [NSString stringWithFormat:@"%ld", (long)[assets count]];
    }else{
        desLabel.text   = @"无";
        leftImageView.image = [UIImage imageNamed:@"icon_none_img.png"];
    }
    groupLabel.text         = assetCollection.localizedTitle;

    
}

- (void)bind:(ALAssetsGroup *)assetsGroup
{
    self.assetsGroup            = assetsGroup;
    
    CGImageRef posterImage      = assetsGroup.posterImage;
    
    leftImageView.image        = [UIImage imageWithCGImage:posterImage scale:1.0 orientation:UIImageOrientationUp];
    groupLabel.text         = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    desLabel.text   = [NSString stringWithFormat:@"%ld", (long)[assetsGroup numberOfAssets]];
}


@end


#pragma mark - TJWAssetGroupViewController

@interface TJWAssetGroupViewController()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) NSMutableArray *groups;

@property (nonatomic, strong) PHFetchResult<PHAssetCollection *> *assetCollections;

@end

@implementation TJWAssetGroupViewController

- (id)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
        self.preferredContentSize=kPopoverContentSize;
#else
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
            [self setContentSizeForViewInPopover:kPopoverContentSize];
#endif
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupButtons];
    [self localize];
    [self setupGroup];
    self.tableView.tableFooterView = [[UIView alloc]init];
}


#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - Setup


- (void)setupButtons
{
    TJWAssetPickerController *picker = (TJWAssetPickerController *)self.navigationController;
    
    if (picker.showCancelButton)
    {
        UIBarButtonItem *rightBar = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"取消", nil)style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
        
        self.navigationItem.rightBarButtonItem = rightBar;
        
    }
}

- (void)localize
{
    self.title = NSLocalizedString(@"相簿", nil);
    
}

- (void)setupGroup
{
    if (!self.groups)
        self.groups = [[NSMutableArray alloc] init];
    else
        [self.groups removeAllObjects];
    
    TJWAssetPickerController *picker = (TJWAssetPickerController *)self.navigationController;

    if (kSystemEightAfterVerson ) {
        
        
        
        self.assetCollections = picker.assetCollections;
        
        [self reloadData];

      
        
        
    }else{
        if (!self.assetsLibrary)
            self.assetsLibrary = [self.class defaultAssetsLibrary];
        
       
        ALAssetsFilter *assetsFilter = picker.assetsFilter;
        ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *group, BOOL *stop) {
            
            if (group)
            {
                [group setAssetsFilter:assetsFilter];
                if (group.numberOfAssets > 0 )
                    [self.groups addObject:group];
            }
            else
            {
                [self reloadData];
            }
        };
        
        
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
            
            [self showNotAllowed];
            
        };
        
        // Enumerate Camera roll first
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                          usingBlock:resultsBlock
                                        failureBlock:failureBlock];
        
        // Then all other groups
        NSUInteger type =
        ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
        ALAssetsGroupFaces | ALAssetsGroupPhotoStream;
        
        [self.assetsLibrary enumerateGroupsWithTypes:type
                                          usingBlock:resultsBlock
                                        failureBlock:failureBlock];
    }
    
    
}




#pragma mark - Reload Data

- (void)reloadData
{
    if (kSystemEightAfterVerson) {
        
        [self.tableView reloadData];

    }else{
        if (self.groups.count == 0)
            [self showNoAssets];
        
        [self.tableView reloadData];
 
    }

}


#pragma mark - ALAssetsLibrary

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}


#pragma mark - Not allowed / No assets

- (void)showNotAllowed
{
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
        [self setEdgesForExtendedLayout:UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom];
    
    self.title              = nil;
    
    UIImageView *padlock    = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.bounds.size.width/2-65, 10, 130, 160) ];
    padlock.image =  [UIImage imageNamed:@"AssetsPickerLocked@2x.png"];
    padlock.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *title          = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.preferredMaxLayoutWidth = 304.0f;
    
    UILabel *message        = [UILabel new];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.preferredMaxLayoutWidth = 304.0f;
    
    title.text              = NSLocalizedString(@"此应用无法使用您的照片或视频。", nil);
    title.font              = [UIFont boldSystemFontOfSize:17.0];
    title.textColor         = [UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1];
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = NSLocalizedString(@"你可以在「隐私设置」中启用存取。", nil);
    message.font            = [UIFont systemFontOfSize:14.0];
    message.textColor       = [UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1];
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    UIView *centerView = [UIView new];
    centerView.translatesAutoresizingMaskIntoConstraints = NO;
    [centerView addSubview:padlock];
    [centerView addSubview:title];
    [centerView addSubview:message];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(padlock, title, message);
    
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:padlock attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:centerView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:padlock attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:message attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:padlock attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[padlock]-[title]-[message]|" options:0 metrics:nil views:viewsDictionary]];
    
    UIView *backgroundView = [UIView new];
    [backgroundView addSubview:centerView];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    self.tableView.backgroundView = backgroundView;
}

- (void)showNoAssets
{
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
        [self setEdgesForExtendedLayout:UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom];
    
    UILabel *title          = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.preferredMaxLayoutWidth = 304.0f;
    UILabel *message        = [UILabel new];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.preferredMaxLayoutWidth = 304.0f;
    
    title.text              = NSLocalizedString(@"没有照片或视频。", nil);
    title.font              = [UIFont systemFontOfSize:26.0];
    title.textColor         = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = NSLocalizedString(@"您可以使用 iTunes 将照片和视频\n同步到 iPhone。", nil);
    message.font            = [UIFont systemFontOfSize:18.0];
    message.textColor       = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    UIView *centerView = [UIView new];
    centerView.translatesAutoresizingMaskIntoConstraints = NO;
    [centerView addSubview:title];
    [centerView addSubview:message];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(title, message);
    
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:centerView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:message attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]-[message]|" options:0 metrics:nil views:viewsDictionary]];
    
    UIView *backgroundView = [UIView new];
    [backgroundView addSubview:centerView];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    self.tableView.backgroundView = backgroundView;
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (kSystemEightAfterVerson) {
        return self.assetCollections.count;
    }
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    TJWAssetGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[TJWAssetGroupViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    if (kSystemEightAfterVerson) {
        
        [cell bindcolection:[self.assetCollections objectAtIndex:indexPath.row]];
        
    }else{
        [cell bind:[self.groups objectAtIndex:indexPath.row]];

    }
    
    return cell;
}


#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TJWAssetViewController *vc = [[TJWAssetViewController alloc] init];
    if (kSystemEightAfterVerson) {
        vc.phassetsGroup = [self.assetCollections objectAtIndex:indexPath.row];
        vc.naviationTitle = vc.phassetsGroup.localizedTitle;
        
    }else{
        vc.assetsGroup = [self.groups objectAtIndex:indexPath.row];
        vc.naviationTitle =  [vc.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    }
    
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions

- (void)dismiss:(id)sender
{
    TJWAssetPickerController *picker = (TJWAssetPickerController *)self.navigationController;
    
    if ([picker.TJWdelegate respondsToSelector:@selector(assetPickerControllerDidCancel:)])
        [picker.TJWdelegate assetPickerControllerDidCancel:picker];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end

#pragma mark - TJWAssetPickerController

@implementation TJWAssetPickerController

- (id)init
{
    TJWAssetGroupViewController *groupViewController = [[TJWAssetGroupViewController alloc] init];
    
    if (self = [super initWithRootViewController:groupViewController])
    {
        _maximumNumberOfSelection       = 10;
        _minimumNumberOfSelection       = 0;
       
        
        if(kSystemEightAfterVerson){
            
            PHFetchOptions*options = [[PHFetchOptions alloc]init];
            options.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
            options.includeHiddenAssets = YES;
            _assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:options];
        }else{
            
            _assetsFilter                   = [ALAssetsFilter allPhotos];
            _selectionFilter                = [NSPredicate predicateWithValue:YES];

        }
        
        
        
        
        _showCancelButton               = YES;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
        self.preferredContentSize=kPopoverContentSize;
#else
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
            [self setContentSizeForViewInPopover:kPopoverContentSize];
#endif
        [self.navigationBar setBackgroundImage:[TJWAssetPickerController createImageWithColor:[UIColor colorWithRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0]] forBarMetrics:UIBarMetricsDefault];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
     self.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject,NSDictionary *bindings){
         
        if ([evaluatedObject isKindOfClass:[ALAsset class]]) {
            
            if ([[(ALAsset *)evaluatedObject valueForProperty:ALAssetPropertyType]isEqual:ALAssetTypeVideo]) {
                NSTimeInterval duration = [[(ALAsset *)evaluatedObject valueForProperty:ALAssetPropertyDuration]doubleValue];
                
                return duration >= 5;
                
            }
                
            return  YES;
            
        }else if([evaluatedObject isKindOfClass:[PHAsset class]]){
            
            PHAsset *asset = (PHAsset *)evaluatedObject;
            
            if (asset.mediaType == PHAssetMediaTypeVideo) {
                
                return asset.duration >= 5;
                
            }
                
            return  YES;
            
        }        
        return YES;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

+ (UIImage*)createImageWithColor:(UIColor*)color{
    
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}


@end
