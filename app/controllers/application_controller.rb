class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_action :configure_permitted_parameters, if: :devise_controller?

  # antes de entrar a la pagina de inicio , necesita autenticar luego de eso me redirige a root_path => posts#index
  before_action :authenticate_user!
  
  protected
  
  def configure_permitted_parameters
    # parametros que permite cuando me registro a la aplicacion
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :avatar])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :avatar])
  end
end
