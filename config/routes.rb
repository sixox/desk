Rails.application.routes.draw do
  resources :vacations do
    member do
      patch "confirm", to: "vacations#confirm"
      get "confirm", to: "vacations#confirm"
    end
    collection do
      get 'managment'
      get 'by_user'
    end
  end
  devise_for :users
  root 'home#index'
  resources :customers
  resources :pis
  resources :projects do
    resources :ballance_projects
    resources :pis
    resources :cis
    resources :bookings do
      member do
        get 'edit_picked_up'
        get 'edit_status'
      end
    end
  end
  resources :cis do
    resources :swifts
  end
  resources :ballances do
    resources :spis
    resources :scis
  end
  resources :suppliers
  resources :payment_orders do
    member do
      patch "confirm", to: "payment_orders#confirm"
      get "confirm", to: "payment_orders#confirm"
      patch "delivered", to: "payment_orders#delivered"
      get "delivered", to: "payment_orders#delivered"
      patch "reject", to: "payment_orders#reject"
      get "reject", to: "payment_orders#reject"

    end
    collection do
      get 'not_paid'
      get 'not_confirmed'
      get 'finished'
      get 'pending'
      get 'not_delivered'
      get 'mine'
      get 'confirmable'
      get 'reports'
      get 'rejected'
    end
    resources :comments

  end
  resources :comments
  resources :clients
  resources :swifts do
    member do
      patch "confirm", to: "swifts#confirm"
      get "confirm", to: "swifts#confirm"
      patch "reject", to: "swifts#reject"
      get "reject", to: "swifts#reject"
    end
  end
  resources :banks


  get 'member/:id', to: 'members#show', as: 'member'
  get 'edit_description', to: 'members#edit_description', as: 'edit_member_description'
  patch 'update_description', to: 'members#update_description', as: 'update_member_description'
  get 'edit_personal_details', to: 'members#edit_personal_details', as: 'edit_member_personal_details'
  patch 'update_personal_details', to: 'members#update_personal_details', as: 'update_member_personal_details'

    # get 'edit_booking_picked_up', to: 'bookings#edit_booking_picked_up', as: 'edit_booking_picked_up'



  end
