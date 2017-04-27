Pod::Spec.new do |s|
s.name         = 'LFPhotoBrowser'
s.version      = '1.0.6'
s.summary      = 'A clone of UIImagePickerController, support picking multiple photos、 video and edit photo'
s.homepage     = 'https://github.com/lincf0912/LFPhotoBrowser'
s.license      = 'MIT'
s.author       = { 'lincf0912' => 'dayflyking@163.com' }
s.platform     = :ios
s.ios.deployment_target = '7.0'
s.source       = { :git => 'https://github.com/lincf0912/LFPhotoBrowser.git', :tag => s.version, :submodules => true }
s.requires_arc = true
s.resources    = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/*.bundle'
s.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/*.{h,m}','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/**/*.{h,m}','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/category/**/*.{h,m}'
s.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/model/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/model/**/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/type/*.h','LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/loadingView/VideoProgressView.h'

# LFPlayer模块
s.subspec 'LFPlayer' do |ss|
ss.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/videoPlayer/*.{h,m}'
ss.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/videoPlayer/*.h'
end

# LFActionSheet模块
s.subspec 'LFActionSheet' do |ss|
ss.source_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/vendors/LFActionSheet/*.{h,m}', 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/vendors/LFActionSheet/**/*.{h,m}'
ss.public_header_files = 'LFPhotoBrowserDEMO/LFPhotoBrowserDEMO/class/vendors/LFActionSheet/LFActionSheet.h'
end

s.dependency 'SDWebImage/Core', '~> 3.8.2'

end
