Dummy::Application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # ActiveAdmin.routes(self)
  # devise_for :admin_users, ActiveAdmin::Devise.config, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
end