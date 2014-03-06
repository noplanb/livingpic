class OccasionsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  before_filter :requires_current_user
  include AppHelper
    
  # Find any registered occasions based upon the longitude and latitude
  def find
    occasions = Occasion.near(:longitude => params[:long],:latitude => params[:lat]) 
    respond_to do |format|
      format.mobile occasions.to_json.only(:name)
    end
  end
  
  # The user can create a new occasion.  If he passes the name of an occasion that already exists for that user, we return the same occasion (although this
  # condition should be stopped at the server)
  def create
    occasion = Occasion.get_or_create(params[:occasion].only("name").merge(params[:location]||{}).merge(:user_id  => current_user_id))
    render :json => occasion_attributes_for_app_with_thumbnail(occasion, current_user)
  end
    
  # Create a place in the backend to store the population estimates from the participants. 
  def pop_estimate
    OccasionPopEstimate.create!(:user_id => current_user_id, :occasion_id => params[:id], :value => params[:estimate])
    render :text => "OK"
  end  
  
  # Please make this compatible when you replace the stubs in user.rb, occasion.rb, and session.rb
  def occasions_json
    if current_user
      occasions = current_user.relevant_occasions.map{|o| o.attributes_for_app(current_user_app_version)}
      logger.info "occasions_json returning #{occasions.length} occasions with ids #{occasions.map{ |o| o['id'] }}"
      render :json  => occasions
    else
      render :json => []
    end
  end
  
  # GARF - if there isn't a current user, we should send a special error that tells the 
  # app to check in the user again
  def is_updated
    if current_user
      render :text => Occasion.find(params[:id]).new_photos_for(current_user).length
    else
      render :text => 0
    end
  end

  def gallery_json
    occasion = Occasion.find(params[:id] || params[:occasion_id])
    if current_user
      render :json => {:occasion => occasion_attributes_for_app_with_thumbnail(occasion, current_user), :gallery => occasion.gallery_for_user(current_user)} 
      occasion.viewed_by(current_user)
    else
      render :json => {}
    end
  end

  # This is the new method to call to update a single occasion.  The gallery is now part of the occasion element.
  # If a time parameter is provided, we only return a result if the occasion has had content added since the time elment
  def get
    occasion = Occasion.find(params[:id])
    # GARF - Security hole: we need to check that the user has access to this occasion
    if current_user
      time = (params[:time] && DateTime.parse(params[:time]) rescue nil) || 10.years.ago
      if occasion.content_updated_on && occasion.content_updated_on < time
        render :json  => {}
      else
        render :json => occasion_attributes_for_app_with_thumbnail(occasion, current_user)
      end
      occasion.viewed_by(current_user)
    else
      render :json => {}
    end
  end

  # ##############
  # Inivitations
  # ##############

  def invite
    invitees = JSON.parse(params[:invitees]).compact
    occasion = Occasion.find(params[:occasion_id])
    if invitees
      invitees.each do |invitee_params|
        cr = ContactRecord.create_or_update( ContactRecord.format_from_device(invitee_params).merge(:source_id => current_user_id) )
        current_user.invite(cr.user,occasion) if cr.user
      end
    else
      raise "Doh - didn't get any invitees"
    end
    occasion.reload
    render :json => occasion_attributes_for_app_with_thumbnail(occasion, current_user)
  end

  private


end
