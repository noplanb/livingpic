module AppHelper
  
  EMPTY_OCCASION_THUMBNAIL_PATH = NoPlanB::Helpers::DeviceAssetPathHelper.device_image_path 'livingpic/empty_occasion_thumbnail.png'
  
  def thumbnail_url(occasion, user)
    path = occasion.thumbnail_path_for_user(user) || EMPTY_OCCASION_THUMBNAIL_PATH
    path.match("^http") ? path : "#{request.protocol}#{request.host_with_port}#{path}"
  end
  
  def occasion_attributes_for_app_with_thumbnail(occasion, user)
    p = occasion.photo_for_user(user)
    occasion.attributes_for_app.merge :thumb_id => (p && p.id)
  end
  
  # Take a vesrion string and pull out the actual numeric version
end
