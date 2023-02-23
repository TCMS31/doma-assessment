Rails.application.routes.draw do
  root to: "homepage#index"

  get "up", to: "health#show", as: :health

  resources :questions, only: %i[index] do
    collection do
      get :result
      post :submit_answer
    end
  end
end
