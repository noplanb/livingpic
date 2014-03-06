//
//  GetAlbumPhotos.h
//  snapshot
//
//  Created by Farhad Farzaneh on 7/5/13.
//
//

#import <Cordova/CDVPlugin.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AlbumInterface : CDVPlugin 

-(void) getPhotosWithThumbs:(CDVInvokedUrlCommand*)command;
-(void) createAlbum:(CDVInvokedUrlCommand*)command;
-(void) albumExists:(CDVInvokedUrlCommand*)command;
-(void) saveImage:(CDVInvokedUrlCommand*)command;
-(void) imageExists:(CDVInvokedUrlCommand*)command;
-(void) loopback:(CDVInvokedUrlCommand*)command;

@end
