Rails.application.routes.draw do

  root 'pages#home'

  post 'pages/home' => 'pages#home'
  get 'pages/home' => 'pages#home'
  post 'pages/:followerid/filter' => 'pages#filter'
  get 'pages/:followerid/filter' => 'pages#filter'

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


  get "newdocument", to: "epubs#new"

  get "login", to: "pages#login"
  get "about", to: "pages#about"

  get "signup", to: "users#new"
  get "mysettings", to: "users#edit"

  get "myideas", to: "ideas#index"
  get "myvocab", to: "expressions#index"

  get "search", to: "pages#search"
  get "recharge", to: "pages#mana"


  post "login", to: "sessions#create"
  post "logout", to: "sessions#destroy"

  patch 'documents/:id/update_progress', to: 'documents#update_progress'
  patch 'documents/:id/update_locations', to: 'documents#update_locations'

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
    patch :mark_all_read, on: :collection
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


  resources :documents do
      patch 'update_progress'
      patch 'update_locations'
  end

  resources :highlights do
    patch 'update_score'
  end
  
  resources :replies do
    patch 'update_score'
  end

  resources :ideas
  resources :expressions

end
