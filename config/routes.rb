Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "jobs/:job_id/complete", to: "jobs#complete"
      resources :jobs, only: [:create]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end