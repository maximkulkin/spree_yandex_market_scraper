Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :products do
      resource :yandex_market_info, :only => [:edit, :update],
        :controller => 'yandex_market_info'
    end
  end
end
