Rails.application.routes.draw do
  get 'tweet/index'

  get 'tweet/index' => 'tweet#index'
  post 'tweet/addKeyword' => 'tweet#addKeyword'
  delete 'tweet/deleteKeyword' => 'tweet#deleteKeyword'

  get 'tweet/getTweets' => 'tweet#getTweets'

  delete 'tweet/resetDB' => 'tweet#resetDB'
  delete 'tweet/deleteAllTweets' => 'tweet#deleteAllTweets'

  get 'tweet/getSentiments' => 'tweet#getSentiments'
  get 'tweet/getKeywords' => 'tweet#getKeywords'
  get 'tweet/getDimensions' => 'tweet#getDimensions'
  get 'tweet/train_classifier' => 'tweet#train_classifier'
  post 'tweet/test_classifier' => 'tweet#test_classifier'

  get 'tweet/getDemocratsList' => 'tweet#getDemocratsList'
  get 'tweet/getRepublicanList' => 'tweet#getRepublicanList'
  get 'tweet/get10Tweets' => 'tweet#get10Tweets'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'tweet#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
