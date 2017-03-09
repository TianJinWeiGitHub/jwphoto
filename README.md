# jwphoto
兼容 8.0之前和之后，之前时候ALASset 之后时候PHAsset
使用简单

   TJWAssetPickerController *zye = [[TJWAssetPickerController alloc]init];
        zye.maximumNumberOfSelection = 9;
        zye.TJWdelegate = self;
        
        [self presentViewController:zye animated:YES completion:nil];
        
        初始化 然后给最大选择张数  制定代理
        
        
        注意代理回调
        -(void)assetPickerController:(TJWAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets;
      这里使用的时候需要判断assets内存储对象类型是ALAsset 还是PHAsset  区分处理 ，后期改进
