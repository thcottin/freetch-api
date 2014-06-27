ParkApp::Application.routes.draw do

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :update] do
        collection do
          match '/me', to: 'users#show', via: :get
        end
      end
      ## Needed to allow cross origin request from webapp
      match '/users/:id', to: 'users#update', via: :post
      resources :sweetches, only: [:create, :update, :index]
      match '/sweetches/:id', to: 'sweetches#update', via: :post
      # Get the messages to display on the views
      match '/message_views', to: 'message_views#index', as: :message_views, via: :get
      resources :posts

    end
  end
  match '/admin', to: 'admin#index', via: :get
  match '/admin', to: 'admin#create', via: :post
  match '/admin/:id', to: 'admin#destroy', as: :delete_fake, via: :delete

end
