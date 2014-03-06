// NOTE: we are calling the app w/in app (yuk!) because the context of 'this' changes when we are in an event handler, 
// at that point it points to the event and not to this object that we define
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

var app = {
    location: null,
    contacts: null,
    timer: null,
    
    deviceready: function() {
        // Was for testing only - no longer necessary
        // this.report('deviceready');
        alert("device ready")
        return
        console.log("device is ready");
        this.getContacts();
        app.bindButtons();
        this.initUserState();
        // Initialize the push notification code        
        // Commented out to reduce log noise - this is for push notification
        // initPushwoosh(cordova);
    },
    
    
    // Initialize the application - this is the stuff that comes from our server code 
    // Keep it here for now for encapsulation
    initUserState: function() {
      var user = current_user();
      console.log("current_user = "+user);
      if (user)
        handle_registration({"user":user}) 
      else
        handle_registration({"fresh":true}) 

      initialize_view() ;
      // app.getContacts()
      // $.mobile.changePage("#invite");        
    },
    
    bindButtons: function(){
//        Bind to the front page buttons
      $('.j_camera_trigger').click(app.takePicture)

      // $('#launchCamera').click(app.takePicture)
      // 
      // // Load the album and choose the image from there
      // $('#loadAlbum').click(function() {
      //   app.loadFromAlbum();
      // })
      //  
      // $('#loadContacts').click(function() {
      //   app.getContacts();
      // })
      //   
      // $('#loadGpsCoordinates').click(function() {
      //   app.getLocation();
      // })
      // 
      // $('#sendSms').click(function() {
      //   app.sendSampleSms();
      // })
      
      
    },
    
    // ================
    // = Take a Photo =
    // ================
    takePicture:function() {
       // I think this provides a single photo in object format
      // navigator.device.capture.captureImage(app.captureSuccess,app.captureError,{limit:1})
       navigator.camera.getPicture(app.captureSuccess,app.captureError,
       {
         quality: 50,
         destinationType: Camera.DestinationType.FILE_URI
       })      
    },
    
    captureError: function(error) {
      alert("Error capturing the image: " + error);
    },
    captureSuccess:function(imageDataUrl) {
      alert("Successfully captured the image at "+ imageDataUrl);
      app.uploadPhoto(imageDataUrl);
      $('#displayedImage').attr('src',imageDataUrl);
    },
    
    // =========================
    // = Load Photo from Album =
    // =========================
    loadFromAlbum: function() {
      navigator.camera.getPicture(app.albumSuccess,app.albumError,
      {
        sourceType: Camera.PictureSourceType.PHOTOLIBRARY,
        destinationType: Camera.DestinationType.FILE_URI
      })
    },
    
    albumSuccess:function(imageDataUrl) {
      alert("Successfully got the image from the album at "+ imageDataUrl)
      app.uploadPhoto(imageDataUrl);
      
    },
    albumError:function(errorMessage) {
      alert("Error loading from album")
    },
    
    // Upload files to server
    uploadPhoto: function(imageURI) {
        var options = new FileUploadOptions();
        options.fileKey="pic";
        options.fileName=imageURI.substr(imageURI.lastIndexOf('/')+1);
        // console.log("filename = " + options.fileName);
        options.mimeType="image/jpeg";

        var params = new Object();
        params.latitude = app.location.coords.latitude;
        params.longitude = app.location.coords.longitude;

        options.params = params;

        var ft = new FileTransfer();
        alert("Starting the upload of "+ imageURI);
        ft.upload(imageURI, encodeURI(Config.base_url() + "/photos/create"), app.uploadSuccess, app.uploadFailure, options);
    },

    uploadSuccess: function(r) {
        alert("DONE uploading")
        console.log("Code = " + r.responseCode);
        console.log("Response = " + r.response);
        console.log("Sent = " + r.bytesSent);
    },

    uploadFailure: function(error) {
        alert("An error has occurred: Message = " + error.message);
        console.log("upload error source " + error.source);
        console.log("upload error target " + error.target);
    },
    

    // ============
    // = Contacts =
    // ============
    getContacts: function() {
      navigator.contacts.find(["displayName","name", "phoneNumbers", "emails"],app.contactsSuccess,app.contactsError,
      {
        multiple:true,
      })
    },
    
    contactsSuccess:function(contacts) {
      app.contacts = contacts;
      alert("Successfully found " + contacts.length + " contacts")
      // Now convert the contacts into a model that we want to save it for display
      // 2012-09-12 - it's very much like it already is
      // var formatted_contacts = new Array(contacts.length);
      for ( i=0; i < contacts.length; i++ ) {
        // formatted_contacts[i] = {fullname: contacts[i].name.formatted, id:contacts[i].id}
        contacts[i].fullname = contacts[i].name.formatted;
      }
      set_contact_list(contacts);
      create_indexed_contact_list();
      // app.uploadContacts(contacts.slice(0,3))
      // window.setup_auto_complete();
    },
    
    // Returns an error object
    contactsError:function(error) {
      alert("Error loading contacts")
    },
    
    uploadContacts:function(contacts) {
      alert("posting " + contacts.length + " contacts to "+ Config.base_url() + "/invite");
      $.ajax({
        url: Config.base_url() + "/contacts",
        type: "POST",
        data: {contacts: JSON.stringify(contacts)},
        beforeSend: function(x) {
          if (x && x.overrideMimeType) {
            x.overrideMimeType("application/j-son;charset=UTF-8");
          }
        },
        success: function(result) {
          // OK, seems like we sent the contacts OK, now do something
          alert("Sent them OK")
        },
        error:function(jqXHR, textStatus, errorThrown) {
          alert("Error sending contacts with status "+textStatus+" and errorThrown "+errorThrown);
        }
      })
    },
    
    // =============
    // = Locations =
    // =============
    getLocation: function() {
      app.timer = new Date().getTime()
      navigator.geolocation.getCurrentPosition(app.locationSuccess, app.locationError);
    },
    
    locationSuccess: function(position) {
      console.log(new Date().getTime() - app.timer)
      alert("position = lat " + position.coords.latitude + ", long " + position.coords.longitude)
      app.location = position;
      return position;
    },
    
    locationError: function(error) {
      alert("Error getting location: "+error.message)
    },
    
    // Device-based SMS
    sendSampleSms: function(error) {
      alert("Sending sample SMS")
      window.plugins.smsComposer.showSMSComposerWithCB(app.smsCallback,'6502453537,4156020256',"Texting from my app")
    },
    
    smsCallback: function(result) {
      if(result == 0)
      	alert("Cancelled");
      else if(result == 1)
      	alert("Sent");
      else if(result == 2)
      	alert("Failed.");
      else if(result == 3)
      	alert("Not Sent.");		
    }
        
};

window.handleOpenURL = function(url) {
  console.log("handleOpenURL url="+url);
  var user_id;
  var context_id = getUrlParam(url,'context_id');
  if ( context_id ) {
    console.log("Got context_id "+context_id);
    handle_registration({context_id:context_id})    
  } else if ( user_id = getUrlParam(url,'user_id') )  {
    // get the user parameters and save them in local storage
    console.log("Got user_id "+user_id);
    handle_registration({user_id:user_id});
  } else {
    console.log("in handleOpenURL: got no user_id back");
    handle_registration({unknown_user:true})
    // let's go ahead and run handle_registration with new user    
  }
}

// Here's a function to get the url parameters.  Call it with the parameter name
// and it'll return the value or null
getUrlParam = function(url,name) {
    var results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(url);
    return (results && results[1]) || null
}

