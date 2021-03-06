Weather::Application.routes.draw do
  


  resources :ledgers


  resources :transcriptions


  resources :annotations


  resources :page_types


  resources :pages
  # post 'pages' => 'pages#create', as: "pages_create"


  resources :field_groups


  resources :fields

  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users, except: [:create, :new]

  # Name it however you want

  root :to => "home#index"
  match 'home' => 'home#index', :via => [:get, :post]
  match 'about' => 'home#about', :via => [:get, :post]
  match 'contact' => 'home#contact', :via => [:get, :post]
  get 'transcribe(/:current_page_id)' => 'transcriptions#new', as: "transcribe_page"
  # match 'pagetypes' => 'pagetypes#index', :via => [:get, :post]
  match 'ledgers' => 'ledgers#index', :via => [:get, :post]
  match 'users' => 'users#index', :via => [:get, :post]
  match 'users/:id/profile' => 'users#show', :via => [:get, :post, :put]
  match 'users/:id/edit' => 'users#edit', :via => [:get, :post]
  match 'users/:id/stats' => 'users#stats', :via => [:get, :post]
  match 'new-user' => 'users#new', :via => [:get, :post]
  match 'fieldGroups' => 'fieldgroups#index', :via => [:get, :post]
  match 'fields' => 'fields#index', :via => [:get, :post]
  #match '/avatars/original/missing.png', :via => [:get, :post]
  
  post 'create_page_metadata' => "page_days#create"

  get 'my_transcriptions/:user_id' => 'transcriptions#my_transcriptions', as: "my_transcriptions"

  resources :static_pages
  constraints(StaticPage) do
    get '/(*path)', to: 'static_pages#show', as: 'static'
  end

  devise_scope :user do
    get "login", to: "devise/sessions#new"
    get "logout", to: "devise/sessions#destroy"
  end

end
