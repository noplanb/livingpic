(function(cordova) {

 function AlbumInterface() {}
 
   AlbumInterface.getPhotosFinalCallback = null 

  // Call this to retrieve the photo urls from the album
  // Count will be the number to return
  // reverse is a flag indicating if the data should be returned in reverse order
  AlbumInterface.prototype.getPhotosWithThumbs = function(success, fail, count, offset) {
    AlbumInterface.getPhotosFinalCallback = success;
    reverse = true;
    cordova.exec(this.handleGetPhotos, fail, "AlbumInterface", "getPhotosWithThumbs", [reverse, count, offset]);

    // To go with the params input...
    // cordova.exec(this.handleGetPhotos, fail, "AlbumInterface", "getPhotosWithThumbs", [{"count":count,"offset":offset}]);
  };

  AlbumInterface.prototype.handleGetPhotos = function (results) {
    photos = results.data
    normalized = AlbumInterface.normalizePhotos(photos,results.offset)
    AlbumInterface.getPhotosFinalCallback(normalized)
  }

  AlbumInterface.normalizePhotos = function(photos,offset) {
    for (i=0; i<photos.length; i++){      
      // Return a bogus negative ID since IOS photos don't have IDs
      photo = photos[i]
      photo["id"] = -offset-(i+1)
      photo["display_url"] = photo.image_url
      photo["thumb_display_url"] = 'data:image/png;base64,' + photo.thumbnail_data 
      photo["orientation"] = AlbumInterface.normalizeOrientation(photo.orientation)
    }
    return photos
  }
  
  AlbumInterface.normalizeOrientation = function(ios_orientation){
    if (parseInt(ios_orientation) === 0){
      return 1
    } else {
      return ios_orientation
    }
  }
  
  // Call this to save a photo to the album.  
  // Inputs: 
  // image_id: the id for the image - this is returned in in the callback
  // file_path: the file path for the image
  // album_name: the name of the album to write this to
  // success: the callback when image is saved successfully, called with a hash containing image id
  AlbumInterface.prototype.saveImage = function(image_id, file_path, album_name, success, fail) {
    cordova.exec(success, fail, "AlbumInterface", "saveImage", [image_id, file_path, album_name]);
  };

  // Call this to check if the image still exists in the album
  AlbumInterface.prototype.imageExists = function(image_id, image_url, success, fail) {
    cordova.exec(success, fail, "AlbumInterface", "imageExists", [image_id,image_url]);
  };

  // Call this to save a photo to the album.  Input is the album name
  AlbumInterface.prototype.createAlbum = function(name, success, fail) {
    cordova.exec(success, fail, "AlbumInterface", "createAlbum", [name]);
  };

  // Determines if the album with the indicated name exists
  AlbumInterface.prototype.albumExists = function(name, success, fail) {
    cordova.exec(success, fail, "AlbumInterface", "albumExists", [name]);
  };

  // Determines if the album with the indicated name exists
  AlbumInterface.prototype.loopback = function(success, fail) {
    cordova.exec(success, fail, "AlbumInterface","loopback",[]);
  };

 cordova.addConstructor(function() {
                        if(!window.plugins) window.plugins = {};
                            window.plugins.AlbumInterface = new AlbumInterface();
                        });

})(window.cordova || window.Cordova || window.PhoneGap);
