// Android AlbumInterface Plugin JS

// Note as this interface is currently designed it only allows one call to any of its methods at a time
// because it saves the final callback to each of its methods in a global variable and also uses class methods for normalizing. 
// while this is very cheezy it is ok for now and simple to understand.
// TODO: Make it more robust and create separate instances of album interface for parallel calls. Note this involves some footwork as 
// Cordova creates an instance of us.

// Note I bring in all available fields available for the android api that is currently running on the device
// becuase some like longitude, lat, orientation,
// width, etc may be useful now or in the future. It also makes it easy to inspect in js what is
// available on android and ios. We normalize the params we care most about between ios and android as we need them.

(function(cordova) {

  function AlbumInterface() {}
  
  AlbumInterface.getPhotosFinalCallback = null 

  // Call this to retrieve the photos sorted as most recent first across the entire device.
  AlbumInterface.prototype.getPhotosWithThumbs = function(success, fail, count, offset,filteredAlbums,filterIsInclude) {
    AlbumInterface.getPhotosFinalCallback = success;
    // We indicate that we want to exclude the album "photos" - it's listed and we indicate false for the "include" flag
    cordova.exec(this.handleGetPhotos, fail, "AlbumInterface", "getPhotosWithThumbs", [count, offset, filteredAlbums,filterIsInclude])
  }
  
  // Call this to retrieve the photos sorted as most recent first across the entire device.
  AlbumInterface.prototype.getPhotos = function(success, fail, count, offset) {
    AlbumInterface.getPhotosPhotosFinalCallback = success
    cordova.exec(this.handleGetPhotos, fail, "AlbumInterface", "getPhotos", [count, offset, ["LivingPic"], false])
  }
  
  AlbumInterface.prototype.handleGetPhotos = function (json) {
    photos = JSON.parse(json)
    normalized = AlbumInterface.normalizePhotos(photos)
    AlbumInterface.getPhotosFinalCallback(normalized)
  }
      
  // Call this to retrieve the  url of the fullsize photo.
  AlbumInterface.prototype.getPhotoWithThumbById = function(success, fail, id) {
    AlbumInterface.getPhotoFinalCallback = success
    cordova.exec(this.handleGetPhoto, fail, "AlbumInterface", "getPhotoWithThumbById", [id])
  }
  
  AlbumInterface.prototype.handleGetPhoto = function(json) {
    photo = JSON.parse(json)
    if (photo instanceof Array) {
      photo = photo.first()
    }
    normalized = AlbumInterface.normalizePhoto(photo)
    AlbumInterface.getPhotoFinalCallback(normalized)
  }
  
  AlbumInterface.normalizePhotos = function(photos) {
    for (i=0; i<photos.length; i++){      
      photos[i] = AlbumInterface.normalizePhoto(photos[i])
    }
    return photos
  }
  
  AlbumInterface.normalizePhoto = function(photo) {
    // In thumbnail the id for the fullsize is assumed to be under image_id. We can change this to normalize between android and ios.
    photo.id = parseInt(photo._id)
    
    photo.width = parseInt(photo.width)
    photo.height = parseInt(photo.height)
    if ( isNaN(photo.width) || isNaN(photo.height) ){
      photo.width = parseInt(photo.thumb_width)
      photo.height = parseInt(photo.thumb_height)
    }
    
    photo.display_url = photo._data.match(/^file:/) ?  photo._data : "file://" + photo._data
    if (photo.thumb__data) {
      photo.thumb_display_url = photo.thumb__data.match(/^file:/) ?  photo.thumb__data : "file://" + photo.thumb__data
    } else if (photo.thumb_bmp){
      photo.thumb_display_url  = 'data:image/png;base64,' + photo.thumb_bmp
    } else {
      photo.thumb_display_url = photo.display_url
    }
    return photo
  }
  
  
  // =============================================================
  // = Everything below not tested or functioning yet on Android =
  // =============================================================
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
