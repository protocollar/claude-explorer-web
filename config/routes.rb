Rails.application.routes.draw do
  root "project_groups#index"

  resources :project_groups, only: [ :index, :show ]

  resources :projects, only: [ :index, :show ] do
    resources :project_sessions, only: [ :index, :show ]
  end

  resources :project_sessions, only: [ :show ] do
    resource :tree, only: [ :show ], controller: "project_sessions/trees"
    resources :messages, only: [ :show ]
  end

  resources :session_plans, only: [ :index, :show ]
  resources :tool_uses, only: [ :index ]
  resource :import, only: [ :create ]

  get "up" => "rails/health#show", as: :rails_health_check
end
