Rails.application.routes.draw do
  get 'home/index', to: 'home#index'  # Ensure this route exists
  get 'home/dashboard', to: 'home#dashboard'  # This should also exist
  get 'home/dashboard'
  get 'game/quardo'
  get 'project_login', to: 'projects#project_login'
  post 'project_login', to: 'projects#authenticate'
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
  root 'home#dashboard'
  resources :customers
  resources :pis do
    member do
      get :create_document_form
      post :create_document
      patch :create_document
      patch :update_temp
      get :update_temp_form


      patch "assign_project_form", to: "pis#assign_project_form"
      get "assign_project", to: "pis#assign_project"


    end
    collection do

      get :new_temp
      post :create_temp
      delete :destroy_temp
    end
  end
  resources :projects do
    member do
      get :card
      get :time_line
      get :update_timeline
      get :turnover

    end
    resources :ballance_projects
    resources :pis
    resources :cis
    resources :swifts
    resources :bookings do
      member do
        get 'edit_picked_up'
        get 'edit_status'
        get 'shipping'
        patch :update_images
        delete :delete_all_images
      end
    end
    collection do
      get :list
    end
  end
  resources :cis do
    resources :swifts
    member do
      get :create_document_form
      post :create_document
      patch :create_document
    end
  end
  resources :ballances do
    resources :ballance_projects
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
      patch "hamed_confirm", to: "payment_orders#hamed_confirm"

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
  resources :clients do
    member do
      get "change_status", to: "clients_change_status"
    end
    resources :comments
  end
  resources :swifts do
    member do
      patch "confirm", to: "swifts#confirm"
      get "confirm", to: "swifts#confirm"
      patch "reject", to: "swifts#reject"
      get "reject", to: "swifts#reject"
      get 'edit_amount_before_confirm'
    end
  end
  resources :banks do
    member do
      get :transactions
    end
    collection do
      get :transaction
    end
  end

  resources :transfers do
    member do
      patch "confirm", to: "transfers#confirm"
      get "confirm", to: "transfers#confirm"
      patch "reject", to: "transfers#reject"
      get "reject", to: "transfers#reject"
    end
  end
  resources :deposits
  resources :reports do
    resources :comments
  end
  resources :prices do
    member do
      get "add_price", to: "prices#add_price"

    end
  end

  resources :letter_heads
  resources :accounts
  resources :documents
  resources :assessments do
    collection do
      get :form
      patch :update_form
      get :all
    end
  end

  resources :satisfaction_forms, only: [:index] do
    collection do
      patch :update_all  # For updating all forms at once
      get :result
    end
  end

  resources :meetings do
    resources :actions, only: [:new, :create, :edit, :update, :destroy]
  end







  get 'member/:id', to: 'members#show', as: 'member'
  get 'edit_description', to: 'members#edit_description', as: 'edit_member_description'
  patch 'update_description', to: 'members#update_description', as: 'update_member_description'
  get 'edit_personal_details', to: 'members#edit_personal_details', as: 'edit_member_personal_details'
  patch 'update_personal_details', to: 'members#update_personal_details', as: 'update_member_personal_details'
  get 'members/signatures', to: 'members#signatures', as: 'members_signatures'
  patch 'members/update_signatures', to: 'members#update_signatures', as: 'update_members_signatures'


    # get 'edit_booking_picked_up', to: 'bookings#edit_booking_picked_up', as: 'edit_booking_picked_up'



  end
