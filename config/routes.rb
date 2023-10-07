Rails.application.routes.draw do
  resources :vacations
  devise_for :users
  root 'home#index'

  get 'member/:id', to: 'members#show', as: 'member'
  get 'edit_description', to: 'members#edit_description', as: 'edit_member_description'
  patch 'update_description', to: 'members#update_description', as: 'update_member_description'
  get 'edit_personal_details', to: 'members#edit_personal_details', as: 'edit_member_personal_details'
  patch 'update_personal_details', to: 'members#update_personal_details', as: 'update_member_personal_details'




  get 'new_confirm_vacation', to: 'vacations#edit_confirm_vacation', as: 'edit_vacation_confirm'
  patch 'update_confirm_vacation', to: 'vacations#update_confirm_vacation', as: 'update_vacation_confirm'
  

end
