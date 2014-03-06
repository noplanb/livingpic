//
//  GetAlbumPhotos.m
//  snapshot
//
//  Created by Farhad Farzaneh on 7/5/13.
//
//

#import "AlbumInterface.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Base64.h"

//Private stuff
@interface AlbumInterface()
@property (nonatomic,strong) ALAssetsLibrary *library;
@property (nonatomic,strong) NSMutableDictionary *results;

@property (nonatomic,retain) NSString *callbackId;
@property (nonatomic,retain) NSString *imageUrl;
@property (nonatomic,retain) NSString *trackingId;
@property (nonatomic) NSInteger offset;
@end

@implementation AlbumInterface

NSMutableArray *assets;

@synthesize library = _library;
@synthesize results = _results;

// Lazy initialization of the asset library
-(ALAssetsLibrary *) library
{
    if ( !_library) {
        _library = [[ALAssetsLibrary alloc] init];
    }
    return _library;
}

-(NSMutableDictionary *) results
{
    if ( !_results ) {
        _results = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return _results;
}

#pragma mark Public Methods


// Just part of a simple looback test to determine plugin overhead
//
-(void) loopback:(CDVInvokedUrlCommand*)command {
    [self receivedCommand:command];
    [self sendPluginStandardResult];
}

// Get the URLS for all the photos in the camera roll
// Inputs:
//   reverse: indicates if the results are to be returned in reverse order
//   count: the number of results to return
//   offset: the offset for results to return. 
// Returns:
//   array of image URL's
-(void) getPhotosWithThumbs:(CDVInvokedUrlCommand*)command {

  // FF: I was in the middle of updting this to work with a params input rather thana long list
  // of arguments so it would be easier to maintain and also clearer to the user, but backed out
  // in order to release...
  // NSString *COUNT = @"count";
  // NSString *REVERSE = @"reverse";
  // NSString *OFFSET = @"offset";
  
  // [self receivedCommand:command];
  
  // NSDictionary *options = (NSDictionary *)command.arguments[0];
  
  // BOOL reverse = [self isPresent:options[REVERSE]] ? [options[REVERSE] boolValue] : YES;
  // NSInteger count = [self isPresent:options[COUNT]] ? [options[COUNT] integerValue] : 0;
  // self.offset = [self isPresent:options[OFFSET]] ? [options[OFFSET] integerValue] : 0;

    [self receivedCommand:command];
    BOOL reverse = [[command.arguments objectAtIndex:0] isEqual: [NSNull null]] ? NO : [[command.arguments objectAtIndex:0] boolValue] ;
    NSInteger count = [[command.arguments objectAtIndex:1] isEqual:[NSNull null]] ? 0 : [[command.arguments objectAtIndex:1] intValue] ;
    self.offset = [[command.arguments objectAtIndex:2] isEqual:[NSNull null]] ? 0 : [[command.arguments objectAtIndex:2] intValue] ;
    
    [self retrieveAssets: reverse withCount:count andOffset:self.offset];
    
    
    //    Not sure the code below is necessary
//    self.results[@"completed"] = @NO;
//    self.results[@"data"] = assets;
//    CDVPluginResult* pluginResult  = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.results];
//    pluginResult.keepCallback = @YES;
//    
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    
}

// Create an album with the indicate name if it doesn't already exist
// Inputs:
//   album_name: the name of the album to be created
// Returns results hash with
//   album_name: the name of the album that that was created or already existed
//   new: boolean indicating if it was created or if it existed
-(void) createAlbum:(CDVInvokedUrlCommand*)command
{
    [self receivedCommand:command];
    NSString *albumName = [command.arguments objectAtIndex:0];
    self.trackingId = albumName;
    
    [self findAlbum:albumName withCallback:@selector(doCreateAlbum:)];
}

// Check if the album with indicated name exists
// Inputs:
//   album_name: the name of the album
// Returns a results hash containing:
//   album_name: the name of the input album
//   exists: a boolean indicating whether the album exists or not
- (void) albumExists:(CDVInvokedUrlCommand *)command
 {
     [self receivedCommand:command];
     NSString *albumName = [command.arguments objectAtIndex:0];
     self.trackingId = albumName;
     
     [self findAlbum:albumName withCallback:@selector(albumExistsDone:)];
 }

// Save the image in an album .
// Inputs (to command arguments):
//   image_id: an ID identifying the image to be saved (not interpreted by the plugin - just returned)
//   image_url: the image URL
//   album_name: the name of the album - this should already exist.  It is NOT created if it does not exist.
// Returns a results has containing
//   image_id: input value is simply returned
//   image_url: the new asset url for the image
//   album_name: the album name the image was saved to
//
- (void)saveImage:(CDVInvokedUrlCommand*)command
{
    [self receivedCommand:command];
    self.trackingId = [command.arguments objectAtIndex:0];
    self.imageUrl = [command.arguments objectAtIndex:1];
    NSString *albumName = [command.arguments objectAtIndex:2];
    
    [self findAlbum: albumName withCallback:@selector(gotAlbumForImageSave:)];
}


// Check if an image exists
// Input that is passed includes an image_id and the asset URL
// Returns a results hash with the:
//  image_id: input image id
//  exists: true or false
-(void) imageExists:(CDVInvokedUrlCommand *)command
{
    [self receivedCommand:command];
    self.trackingId = [command.arguments objectAtIndex:0];
    NSString *assetUrl = [command.arguments objectAtIndex:1];
    [self.library assetForURL: [NSURL URLWithString:assetUrl]
                  resultBlock:^(ALAsset *asset) {
                      self.results[@"image_id"] = self.trackingId;
                      self.results[@"exists"] = asset ? @YES : @NO;
                      [self sendPluginStandardResult];
                  }
     
                 failureBlock:^(NSError *error) {
                     NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                     [self operationFailedWithError:error];
                 }
     ];
}

#pragma mark Private Utility Methods

-(void) receivedCommand: (CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;
    [self.results removeAllObjects];
    
}

//General purpose method to call when one of the ALAsset methods fails
-(void) operationFailedWithError: (NSError *)error
{
    [self operationFailedWithMessage:error.localizedDescription];
}

-(void) operationFailedWithMessage: (NSString *)message
{
    NSLog(@"AlbumInterface Error: %@",message);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId ];
}

-(void) sendPluginStandardResult
{
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                         messageAsDictionary:self.results]
                                callbackId:self.callbackId];
}


#pragma mark Private Methods

-(void)doCreateAlbum: (ALAssetsGroup *)album 
{
    if ( album ) {
        self.results[@"album_name"] = self.trackingId;
        self.results[@"new"] = @NO;
        [self sendPluginStandardResult];
    } else {
        ALAssetsLibraryGroupResultBlock resultsBlock = ^(ALAssetsGroup *result) {
            if ( result ) {
                self.results[@"album_name"] = self.trackingId;
                self.results[@"new"] = @YES;
                [self sendPluginStandardResult];
            }
        };
        
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
            NSLog(@"Failed to access library with error %@",error);
            [self operationFailedWithError:error];
        };
        
        [self.library addAssetsGroupAlbumWithName:self.trackingId resultBlock:resultsBlock failureBlock:failureBlock];
    }
        
}

// Called when an album has been created
-(void) confirmAlbumCreated: (ALAssetsGroup *) album
{
    NSString *albumName = [album valueForProperty:ALAssetsGroupPropertyName];
    [self.commandDelegate sendPluginResult: [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:albumName] callbackId:self.callbackId];
}

// Tries to find the album.  It calls the input callback selector
// If there is an error (for e.g. the user does not provide album access), the returns with a operation error
- (void) findAlbum: (NSString *) albumName withCallback: (SEL) callback  {
    NSLog(@"Looking to find album %@",albumName);
    __block BOOL found = NO;
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                            usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                if ( group ) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        NSLog(@"Found album %@", albumName);
                                        [self performSelector:callback withObject:group];
                                        *stop = YES;
                                        found = YES;
                                    }
                                } else
//                                   So lame - just setting stop is supposed to stop the enumeration but I find that it continues and the next one is nil
//                                    so if I've found it, I don't want to call the error function
                                    if ( !found )
                                        [self performSelector:callback withObject:nil];
                            }
                          failureBlock:^(NSError* error) {
                              NSLog(@"Error finding album %@:\nError: %@", albumName, [error localizedDescription]);
                              [self operationFailedWithError:error];
                          }];

}

// Called to present back the response to albumExists
-(void) albumExistsDone: (ALAssetsGroup *) album {
    self.results[@"album_name"] = self.trackingId;
    self.results[@"exists"] = album ? @YES : @NO;
    [self.commandDelegate sendPluginResult: [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.results]
                                callbackId:self.callbackId];
    
}

// Called to indicate that we have found the album that we are going to save the image to
-(void) gotAlbumForImageSave: (ALAssetsGroup *) album {
    NSString *albumName;
    if ( album ) {
        albumName = [album valueForProperty:ALAssetsGroupPropertyName];
        NSLog(@"Starting to save image @ %@ in album %@",self.imageUrl, albumName);
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL( (__bridge CFURLRef)[NSURL URLWithString:self.imageUrl], nil);
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource,0,NULL);
        NSDictionary* metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource,0,NULL);
        
        //        With foundation classes we need to do our own memory management
        CFRelease(imageSource);
        
        [self.library writeImageToSavedPhotosAlbum:imageRef metadata:metadata
                                   completionBlock: ^(NSURL* assetURL, NSError* error) {
                                       
                                       if (error.code == 0) {
                                           NSLog(@"saved image completed:\nurl: %@", assetURL);
                                           
                                           // try to get the asset
                                           [self.library assetForURL:assetURL
                                                         resultBlock:^(ALAsset *asset) {
                                                             // assign the photo to the album
                                                             [album addAsset:asset];
                                                             self.results[@"album_name"] = albumName;
                                                             self.results[@"image_url"] = [[[asset defaultRepresentation] url] absoluteString];
                                                             self.results[@"image_id"] = self.trackingId;
                                                             [self sendPluginStandardResult];
                                                             NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                                                         }
                                                        failureBlock:^(NSError* error) {
                                                            [self operationFailedWithError:error];
                                                        }];
                                       }
                                       else {
                                           [self operationFailedWithError:error];
                                       }
                                   }];
        
        
        CFRelease(imageRef);
    } else {
        [self operationFailedWithMessage:@"Could not find album"];
    }
    
}

// Given the array of assets, just map the URLS
-(NSArray *) convertAssetsToUrls:(NSArray *)assets {
    NSMutableArray *urls = [[NSMutableArray alloc]init];
    
    for ( ALAsset *asset in assets) {
        [urls addObject:[[[asset defaultRepresentation] url] absoluteString]];
    }
    return urls;
}

// Return characteristics of the assets - for example the thumbnail may be returned in base64 format
// The image is returned as a URL, etc.
-(NSArray *) convertAssets: (NSArray *) assets {
    NSMutableArray *imagesInfo = [[NSMutableArray alloc]init];
    // NSLog(@"Converting the assets");
    [Base64 initialize];
    for ( ALAsset *asset in assets) {
        NSMutableDictionary *imageInfo = [[NSMutableDictionary alloc] init];

        // Image URL for the full image
        NSString *imageUrl = [[[asset defaultRepresentation] url] absoluteString];
        [imageInfo setObject: imageUrl forKey:@"image_url"];
        
        // Location information
        CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
        CLLocationCoordinate2D coords = location.coordinate;
        [imageInfo setObject:[NSNumber numberWithFloat:coords.latitude] forKey:@"latitude"];
        [imageInfo setObject:[NSNumber numberWithFloat:coords.longitude] forKey:@"longitude"];

        // Get the thumbnail
        UIImage *thumbnail = [UIImage imageWithCGImage:[asset thumbnail]];
        NSData *thumbnailData =  UIImageJPEGRepresentation(thumbnail, 1.0f);
        NSString *base64Thumbnail = [Base64 encode:thumbnailData];
        [imageInfo setObject:base64Thumbnail forKey:@"thumbnail_data"];

//        Get image dimensions and and orientation from the metadata
        NSDictionary *metadata = [[asset defaultRepresentation] metadata];
        [imageInfo setObject:[metadata objectForKey:@"PixelWidth"] forKey:@"width"];
        [imageInfo setObject:[metadata objectForKey:@"PixelHeight"] forKey:@"height"];
        NSNumber *orientation =[metadata objectForKey:@"Orientation"];
        if ( ! orientation )
            orientation = [NSNumber numberWithInt:1];
        [imageInfo setObject:orientation forKey:@"orientation"];

        // This is the old way of getting that info which apparently is not standard....
        // CGSize size = [[asset defaultRepresentation] dimensions];
        // [imageInfo setObject:[NSNumber numberWithFloat:size.height] forKey:@"height"];
        // [imageInfo setObject:[NSNumber numberWithFloat:size.width] forKey:@"width"];
        // [imageInfo setObject:[NSNumber numberWithInt:[[asset defaultRepresentation] orientation]] forKey:@"orientation"];
        
        [imagesInfo addObject:imageInfo];
    }
    // NSLog(@"Done converting the assets");
    return imagesInfo;
}

-(void) retrieveAssets: (BOOL)reverse withCount:(NSInteger)count andOffset:(NSInteger)offset {
    
    ALAssetsGroupEnumerationResultsBlock assetEnumerator= ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if( result ) {
            [assets addObject:result];
        }
    };
    
    ALAssetsLibraryGroupsEnumerationResultsBlock assetGroupEnumerator =  ^(ALAssetsGroup *group, BOOL *stop) {
        if( group ) {
//            Limit to photos for now
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            // NSLog(@"Group name = %@ with %d assets",[group valueForProperty:ALAssetsGroupPropertyName], group.numberOfAssets);
//            [group enumerateAssetsUsingBlock:assetEnumerator];
            NSRange range;
            NSInteger imageCount = ( count == 0 ) ?  group.numberOfAssets - offset : MIN(count,group.numberOfAssets-offset);
            range = reverse ? NSMakeRange(group.numberOfAssets - imageCount - offset, imageCount)
                            : NSMakeRange(offset, imageCount);
            NSIndexSet *indexes =[NSIndexSet indexSetWithIndexesInRange:range] ;
            [group enumerateAssetsAtIndexes:indexes options: reverse ? NSEnumerationReverse : 0 usingBlock:assetEnumerator];
        } else {
            [self assetLoadDone];
        }
    };
    
//    TEST - this is not where it should be...
    if ( assets )
        [assets removeAllObjects];
    else
        assets = [[NSMutableArray alloc] init];
    
    [self.library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                           usingBlock:assetGroupEnumerator
                         failureBlock: ^(NSError *error) {
                             NSLog(@"Failed to enumerate through library groups");
                             [self operationFailedWithError: error];
                         }
     ];
    
    return;
}

// Called when we are done loading all the assets
-(void) assetLoadDone
{
    NSLog(@"Completed asset load %d",[assets count]);
    self.results[@"completed"] = @YES;
    self.results[@"offset"] = [NSNumber numberWithInt:self.offset];
//    self.results[@"data"] = [self convertAssetsToUrls:assets];
    self.results[@"data"] = [self convertAssets:assets];
    
//    Release the objects now that we are done with them
    [assets removeAllObjects];
    [self sendPluginStandardResult];
}

@end
