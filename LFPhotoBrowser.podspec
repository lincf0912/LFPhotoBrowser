Pod::Spec.new do |s|
s.name         = 'LFPhotoBrowser'
s.version      = '1.1.7'
s.summary      = 'A clone of UIImagePickerController, support picking multiple photos、 video and edit photo'
s.homepage     = 'https://github.com/lincf0912/LFPhotoBrowser'
s.license      = 'MIT'
s.author       = { 'lincf0912' => 'dayflyking@163.com' }
s.platform     = :ios
s.ios.deployment_target = '7.0'
s.source       = { :git => 'https://github.com/lincf0912/LFPhotoBrowser.git', :tag => s.version, :submodules => true }
s.requires_arc = true
s.resources    = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/*.bundle'
s.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/*.{h,m}','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/**/*.{h,m}'
s.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/model/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/model/**/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/type/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/category/UIImage/UIImage+LFPB_Format.h'

# LFPlayer模块
s.subspec 'LFVideoPlayer' do |ss|
ss.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFVideoPlayer/*.{h,m}'
ss.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFVideoPlayer/*.h'
end

# LFActionSheet模块
s.subspec 'LFActionSheet' do |ss|
ss.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFActionSheet/*.{h,m}', 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFActionSheet/**/*.{h,m}'
ss.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFActionSheet/LFActionSheet.h'
end

# LFLoadingView模块
s.subspec 'LFLoadingView' do |ss|
ss.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFLoadingView/*.{h,m}'
ss.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/vendors/LFLoadingView/*.h'
end

s.dependency 'SDWebImage/Core', '~> 3.8.2'

end
