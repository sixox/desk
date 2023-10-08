Rails.application.routes.draw do
  resources :vacations do
    member do
      patch "confirm", to: "vacations#confirm"
      get "confirm", to: "vacations#confirm"
    end
  end
  devise_for :users
  root 'home#index'
  
  resources :customers
  resources :pis
  resources :projects
  resources :cis


    get 'member/:id', to: 'members#show', as: 'member'
    get 'edit_description', to: 'members#edit_description', as: 'edit_member_description'
    patch 'update_description', to: 'members#update_description', as: 'update_member_description'
    get 'edit_personal_details', to: 'members#edit_personal_details', as: 'edit_member_personal_details'
    patch 'update_personal_details', to: 'members#update_personal_details', as: 'update_member_personal_details'



  end
