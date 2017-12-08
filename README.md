# LFPhotoBrowser
* 图片浏览器（更多请见LFPhotoBrowser.h）
* 由于DEMO使用了第三方框架(SDWebImage、AFNetworking)，请使用项目前执行pod install

## Installation 安装

* CocoaPods：pod 'LFPhotoBrowser'
* 手动导入：将LFPhotoBrowser\class文件夹拽入项目中，导入头文件：#import "LFPhotoBrowser.h"，依赖SDWebImage

## 调用代码

* LFPhotoBrowser *pbVC = [[LFPhotoBrowser alloc] initWithImageArray:@[PhotoInfo]];
* [pbVC showPhotoBrowser];

* 设置代理方法，按钮实现
* pbVC.delegate;

## 图片展示

![image](https://github.com/lincf0912/LFPhotoBrowser/raw/master/screenshots/screenshot1.gif)

![image](https://github.com/lincf0912/LFPhotoBrowser/raw/master/screenshots/screenshot2.gif)

## 视频展示

![image](https://github.com/lincf0912/LFPhotoBrowser/raw/master/screenshots/screenshot3.gif)
