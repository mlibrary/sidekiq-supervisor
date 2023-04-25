require "sidekiq/web"
Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  namespace :api do
    namespace :v1 do
      post "jobs/:job_id/complete", to: "jobs#complete"
      resources :jobs, only: [:create]
    end
  end
end
