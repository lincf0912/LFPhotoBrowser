//
//  UIImage+Format.m
//  MEMobile
//
//  Created by LamTsanFeng on 16/9/23.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "UIImage+LFPB_Format.h"
#import "UIImage+MultiFormat.h"

#define _FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define _TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

LFPBImageType LFPBImageDetectType(CFDataRef data) {
    if (!data) return LFPBImageType_Unknow;
    uint64_t length = CFDataGetLength(data);
    if (length < 16) return LFPBImageType_Unknow;
    
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    uint32_t magic4 = *((uint32_t *)bytes);
    switch (magic4) {
        case _FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
            return LFPBImageType_TIFF;
        } break;
            
        case _FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return LFPBImageType_TIFF;
        } break;
            
        case _FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
            return LFPBImageType_ICO;
        } break;
            
        case _FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return LFPBImageType_ICNS;
        } break;
            
        case _FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return LFPBImageType_GIF;
        } break;
            
        case _FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == _FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return LFPBImageType_PNG;
            }
        } break;
            
        case _FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == _FOUR_CC('W', 'E', 'B', 'P')) {
                return LFPBImageType_WebP;
            }
        } break;
    }
    
    uint16_t magic2 = *((uint16_t *)bytes);
    switch (magic2) {
        case _TWO_CC('B', 'A'):
        case _TWO_CC('B', 'M'):
        case _TWO_CC('I', 'C'):
        case _TWO_CC('P', 'I'):
        case _TWO_CC('C', 'I'):
        case _TWO_CC('C', 'P'): { // BMP
            return LFPBImageType_BMP;
        }
        case _TWO_CC(0xFF, 0x4F): { // JPEG2000
            return LFPBImageType_JPEG2000;
        }
    }
    if (memcmp(bytes,"\377\330\377",3) == 0) return LFPBImageType_JPEG;
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return LFPBImageType_JPEG2000;
    return LFPBImageType_Unknow;
}

@implementation UIImage (LFPB_Format)

+ (instancetype)LFPB_imageWithImagePath:(NSString *)imagePath
{
    return [self LFPB_imageWithImagePath:imagePath error:nil];
}

+ (instancetype)LFPB_imageWithImagePath:(NSString *)imagePath error:(NSError **)error
{
    if (imagePath.length == 0) return nil;
    NSError *dataError = nil;
    NSData *imgData = [NSData dataWithContentsOfFile:imagePath options:NSDataReadingMappedIfSafe error:&dataError];
    if (dataError != nil) {
        NSLog(@"%@", dataError.localizedDescription);
        if (error) {
            *error = dataError;
        }
        return nil;
    }
    
    return [self LFPB_imageWithImageData:imgData];
}

+ (instancetype)LFPB_imageWithImageData:(NSData *)imgData
{
//    LFPBImageType imageType = LFImageDetectType((__bridge CFDataRef)imgData);
//    
//    UIImage *image = nil;
//    switch (imageType) {
//        case LFPBImageType_GIF:
//            image = [self sd_animatedGIFWithData:imgData];
//            break;
//        case LFPBImageType_WebP:
//            image = [self sd_imageWithWebPData:imgData];
//            break;
//        default:
//            image = [UIImage imageWithData:imgData];
//            break;
//    }
//    return image;
    return [self sd_imageWithData:imgData];
}

@end
