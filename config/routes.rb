Rails.application.routes.draw do

=begin
   con controllers en devise_for le digo que controlador se usara para sobreescribir el
   devise controller para añadir nuevas funcionalidades
=end
  devise_for :users, path: '',
                     controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

=begin
 ruta inicial pagina inicial aplicacion antes de entrar aca pasa por el application
 controller ejecutando el filtro de auth
=end
  root "posts#index"

  resources :users, only: [:index, :show] do
    member do
      get :friends
    end
  end

  resources :friendships, only: [:create, :update, :destroy]

  resources :posts, except: [:new, :edit, :index] do
    resources :likes,       only: [:create, :destroy]
    resources :comments,    only: [:create, :update, :destroy]
  end

end
