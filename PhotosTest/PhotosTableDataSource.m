//
//  PhotosTableDataSource.m
//  PhotosTest
//
//  Created by Nick on 25/03/2018.
//  Copyright © 2018 Nick Dowell. All rights reserved.
//

#import <Photos/Photos.h>

#import "PhotosTableDataSource.h"

@interface PHAsset (MissingAPIs)

// This is missing from the macOS SDK headers ¯\_(ツ)_/¯
+ (PHFetchResult<PHAsset *> *)fetchAssetsWithOptions:(PHFetchOptions *)options;

@end

#pragma mark -

@interface PhotosTableDataSource ()

@property (nonatomic, strong) PHFetchResult<PHAsset *> *fetchResult;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *sortedAssets;
@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) NSCache<NSString *, NSImage *> *imageCache;

@end

#pragma mark -

@implementation PhotosTableDataSource

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    self.fetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
    
    self.sortedAssets = [NSMutableArray new];
    [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
        [self.sortedAssets addObject:asset];
    }];
    
    self.imageManager = [PHImageManager new];
    
    self.imageCache = [NSCache new];
    
    // Populate the image cache because calling -[PHImageManager requestImageForAsset:...]
    // in -tableView:objectValueForTableColumn:row: causes scrolling to stutter
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.networkAccessAllowed = NO;
        options.synchronous = YES;
        
        [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(60, 40)
                                        contentMode:PHImageContentModeAspectFill options:options
                                      resultHandler:^(NSImage *result, NSDictionary *info) {
                                          if (result == nil) { return; }
                 [self.imageCache setObject:result forKey:asset.localIdentifier];
             }];
        }];
    });
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.sortedAssets.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    PHAsset *asset = [self.sortedAssets objectAtIndex:row];
    
    NSString *identifier = tableColumn.identifier;
    if (identifier.length < 1) {
        return nil;
    }
    
    if ([identifier isEqualToString:@"index"]) {
        return [NSNumber numberWithInteger:[self.fetchResult indexOfObject:asset]];
    }
    
    if ([identifier isEqualToString:@"image"]) {
        __block NSImage *image = [self.imageCache objectForKey:asset.localIdentifier];
        if (image != nil) {
            return image;
        }
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.networkAccessAllowed = NO;
        options.synchronous = YES;
        
        [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(60, 40)
                                    contentMode:PHImageContentModeAspectFill options:options
                                  resultHandler:^(NSImage *result, NSDictionary *info) {
                                      image = result; }];
        
        if (image != nil) {
            [self.imageCache setObject:image forKey:asset.localIdentifier];
        }
        
        return image;
    }
    
    if ([identifier isEqualToString:@"dimensions"]) {
        return [NSString stringWithFormat:@"%lu x %lu", (unsigned long)asset.pixelWidth, (unsigned long)asset.pixelHeight];
    }
    
    if ([identifier isEqualToString:@"favourite"]) {
        return [asset isFavorite] ? @"❤️" : @"";
    }
    
    if ([asset respondsToSelector:NSSelectorFromString(identifier)]) {
        return [asset valueForKey:identifier];
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
    [self.sortedAssets sortUsingDescriptors:tableView.sortDescriptors];
    [tableView reloadData];
}

@end

#pragma mark -

@implementation CLLocation (Comparison)

- (NSComparisonResult)compare:(CLLocation *)otherLocation
{
    return [@(self.coordinate.longitude) compare:@(otherLocation.coordinate.longitude)];
}

@end

#pragma mark -

@implementation PHAsset (Extensions)

- (double)megaPixels
{
    return (self.pixelHeight * self.pixelWidth) / 1000000.0;
}

- (NSComparisonResult)compareDimensions:(PHAsset *)otherAsset
{
    return [@(self.pixelHeight * self.pixelWidth) compare:@(otherAsset.pixelHeight * otherAsset.pixelWidth)];
}

@end
