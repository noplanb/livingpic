# This class is for managing various items that relates to the mobile app
class MobileApp
  HTTP_ERROR_CODES = {
    no_current_user: 401,
    user_not_found: 410
  }

  def self.error_code(condition)
    HTTP_ERROR_CODES[condition]
  end
end