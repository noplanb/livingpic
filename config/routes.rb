# require 'resque/server'
Snapshot::Application.routes.draw do
  # mount Resque::Server.new, :at => "/resque" 
   
  get "landing/landing"
  get "landing/background_cover_test"
  match "landing" => "landing#landing"
  match 'app' => 'app#app', :as => "app"
  match 'l/(:notification_id)' => 'landing#index', :as => 'landing'
  match 'fta' => 'landing#forward_to_app'
  match 'ftb' => 'landing#forward_to_browser_app'

  get "app/app"
  get "app/get_contacts"
  get "app/gallery_test"
  get "app/index"
  get "app/browse"
  get "app/occasions"
  get "app/hosts"
  get "app/host"
  get "app/test_set"
  get "app/test_get"
  get "app/tl"
  get "app/test_no_layout"
  get "app/checkin"
  get "app/test_get_date"
  get "app/store_release"
  get "app/version_mgt_checkin"
  post "app/test_post_date"
  post "app/test_post_json"
  match "app/check_cookies" => 'app#check_cookies', :as => 'check_cookies'
  post "app/upload_log"
  get "app/remote_command"
  
  get "app/web_splash"
  
  post "login/register"
  post "login/login"
  
  match "admin/set_user/(:id)" => 'admin#set_user', :as => 'set_user'
  match "admin/set_notification/(:id)" => 'admin#set_notification', :as => 'set_notification'
  match "admin/vn/:id" => "admin#view_notification", :as => 'view_notification'
  get "admin/notification_gen"
  get "admin/notification_gen"
  post "admin/notification_gen"
  get "admin/vs"

  match "users/show/:id" => 'users#show'
  post "users/new"
  post "users/register_with_password"
  post "users/login_with_password"
  get "users/get_sample_user"
  get "users/clear_user"
  get "users/unsubscribe_sms"
  get "users/subscribe_sms"
  
  match "get_context/(:id)" => 'app#get_context_info'
  get "app/build_page"
  
  get "occasions/occasions_json"
  match "occasions/gallery_json/(:id)" => "occasions#gallery_json"
  match "occasions/get/(:id)"  => "occasions#get"
  
  post "occasions/pop_estimate"
  post "occasions/create"
  post "occasions/get_or_create"
  match "occasions/viewed/(:id)" => "occasions#viewed", :via => :post
  
  post "users/register", :via => :post
  post "users/update", :via => :post

  match "push_device_token" => 'users#push_device_token', :via => :post

  match 'photos/create' => 'photos#create', :via => :post
  post 'photos/test'
  post 'photos/dummy'
  get 'photos/all'
  get "photos/gallery"
  get "photos/test_scroll"

  match "photos/like/:id" => "photos#like", :via => :post
  get "photos/likes"

  match "photos/comment/:id"  => "photos#comment", :via => :post
  get "photos/comments"
  get "photos/get/:id" => "photos#get"
  get "photos/test_orientation_json"
    
  match 'invite' => 'occasions#invite', :via => :post
  match 'tag' => 'social_actions#tag', :via => :post
  
  match 'contacts' => 'users#contacts', :via => :post

  match "ping" => "app#ping"
  
  match "app_monitor/log"  => 'app_monitor#log', :via => :post
  match "app_monitor/errors"  => 'app_monitor#errors', :via => :post
  
  # test stuff
  match 'test/:action' => 'test#action'
  get "users/set/:id"  => 'users#set'

  namespace :admin do
    get "users" => 'users#index'
    get "stats/occasions" => 'stats#occasions'
    get "stats/participants" => 'stats#participants'
    get "stats/photo_data" => 'stats#photo_data'
    get "stats/photos_data" => 'stats#photos_data'
    get "stats/thumb_data" => 'stats#thumb_data'
    get "stats/samsung_photos_data" => 'stats#samsung_photos_data'
    post "stats/post_all_photos_data" => 'stats#post_all_photos_data'
    post "stats/post_photo_data" => 'stats#post_photo_data'
    post "stats/post_thumb_data" => 'stats#post_thumb_data'
    get "vs" => 'admin#vs'
  end

  # resources :photos

  root :to => "app#web_splash"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
