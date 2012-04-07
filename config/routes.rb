Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :admin do
    match '/yandex_market_scrap' => 'yandex_market_scrap#new', :as => 'yandex_market_scrap'
  end
end
