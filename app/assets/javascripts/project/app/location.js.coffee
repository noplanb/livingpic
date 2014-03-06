class window.GeoLocation
  lat: null
  long: null
  @lat_long: => {latitude: this.lat, longitude: this.long}
  
  pos: null
  
  @get_location: =>
    if Config.is_running_on_device()
      Logger.log("Requesting geolocation")
      navigator.geolocation.getCurrentPosition( @location_success, @location_error )
    else
      this.lat = 37
      this.long = -120
                  
  @location_success: (position) =>
    @pos = position
    this.lat = position.coords.latitude
    this.long = position.coords.longitude 
    Logger.log("Set Geolocation coordinates to ("+this.lat + "," + this.long + ")")
  
  @location_error: (error) =>
    Logger.error "Error getting location: "+error.message
    