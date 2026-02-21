Rails.application.routes.draw do
  get "merch_orders/new"
  get "merch_orders/create"
  get "subscriptions/new"
  get "subscriptions/create"

  root 'pages#home'

  get 'pages/home' => 'pages#home'
  get 'pages/following', to: 'pages#following'

  get 'users/:username' => 'users#show'
  get 'users/:id/show_following' => 'users#show_following'
  get 'users/:id/show_followers' => 'users#show_followers'
  get 'users/:id/show_replies' => 'users#show_replies'

  get 'users/:id/follow' => 'users#follow'
  get 'users/:id/unfollow' => 'users#unfollow'


  post 'epubs/:sha3/check_presence', to: 'epubs#check_presence'
  post 'epubs/:id/createfromdb' , to: 'epubs#createfromdb'
  get 'epubs/:id/createfromdb'  , to: 'epubs#createfromdb'


  get 'highlights/:id' => 'highlights#show'
  post 'highlights/:id' => 'highlights#show'
  post "richcomment" , to: 'highlights#create'

  post '/gemini/define',  to: 'gemini#define'
  post '/gemini/imagine', to: 'gemini#imagine'

  get "newdocument", to: "epubs#new"

  get "login", to: "pages#login"
  get "about", to: "pages#about"

  get "signup", to: "users#new"
  get "mysettings", to: "users#edit"

  get "myvocab", to: "expressions#index"

  get "search", to: "pages#search"
  get "recharge", to: "pages#mana"


  post "login", to: "sessions#create"
  post "logout", to: "sessions#destroy"

  patch 'documents/:id/update_progress', to: 'documents#update_progress'
  patch 'documents/:id/update_locations', to: 'documents#update_locations'
  get "/documents/not_public", to: "documents#not_public", as: :document_not_public

  post 'users/:id/update_font', to: 'users#update_font'
  patch 'users/:id/hook', to: 'users#update_hooked'
  patch 'users/:id/switch_mode', to: 'users#switch_mode'
  patch 'users/:id/update_votes', to: 'users#update_votes'
  patch 'users/:id/update_data', to: 'users#update_data'
  patch 'users/:id/update_profile', to: 'users#update_profile'

  post 'users/:id/plusonemana', to: 'users#plusonemana'
  post 'users/:id/minusonemana', to: 'users#minusonemana'
  post 'users/:id/plustwomana', to: 'users#plustwomana'
  post 'users/:id/minustwomana', to: 'users#minustwomana'


  patch 'highlights/:id/update_score', to: 'highlights#update_score'
  patch 'replies/:id/update_score', to: 'replies#update_score'

  
  resources :notifications, only: [] do
      collection do
        patch :mark_all_read
        delete :clear_all
      end
  end

  resources :epubs do
    get 'createfromdb'
    
    collection do
      get 'available'
      get 'search'
    end
  end

  resources :users do
    get 'follow'
    get 'unfollow'
    get 'show_following'
    get 'show_followers'
    get 'show_replies'
    patch 'hook'
    patch 'switch_mode'

    patch 'update_votes'
    patch 'update_profile'
    patch 'update_data'
  end

  resources :users do
    member do
      post   :follow
      delete :unfollow
      post   :approve_follow_request
      post   :reject_follow_request
      get    :show_follow_requests
    end
  end

  resources :documents do
    member do
      patch :update_progress
      patch :update_locations
      patch :update_settings
    end
  end

  resources :highlights do
    patch 'update_score'
  end
  
  resources :replies do
    patch 'update_score'
  end

  resources :expressions

  resources :merch_orders, only: [:new, :create, :show]

  resources :subscriptions, only: [:new, :create] do
    collection do
      get :success
      delete :downgrade
    end
  end

  get '/subscriptions/success', to: 'subscriptions#success', as: :subscriptions_success
  get '/subscriptions/downgrade', to: 'subscriptions#downgrade', as: :subscriptions_downgrade
  
  post '/webhooks/stripe', to: 'webhooks#stripe'

  get "/extension_modal", to: "extensions#modal"
  get "/extension_token", to: "extensions#token", as: :extension_token


  # Agent API (for AI bots)
  namespace :api do
    namespace :v1 do
      scope :agents do
        post :register, to: "agents#register"
        post :claim, to: "agents#claim"
        get :status, to: "agents#status"
      end
      get "emojis", to: "emojis#index"
      resources :epubs, only: [:index], controller: "epubs" do
        collection do
          get :search
        end
        member do
          post :documents, to: "epubs#create_document"
        end
      end
      resources :highlights, only: [:index, :show], controller: "highlights" do
        member do
          post :vote
        end
      end
      post "highlights", to: "highlights#create"
      post "replies", to: "replies#create"
      resources :replies, only: [:show], controller: "replies" do
        member do
          post :vote
        end
      end
      resources :documents, only: [:index, :show], controller: "documents" do
        member do
          get :read
          post :resolve_cfi
        end
      end
    end
  end

  # Human claim flow (browser)
  get "claim/success", to: "claims#success", as: :claim_success
  get "claim/:claim_token", to: "claims#show", as: :claim
  post "claim", to: "claims#create"
end
