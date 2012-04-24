Spree::Admin::ProductsController.class_eval do
  create.before :scrap_product_data_from_yandex_market

  def scrap_product_data_from_yandex_market
    return if params[:yandex_market_link].blank?

    SpreeYandexMarketScraper::Scraper.scrap_and_update(params[:yandex_market_link], @product)
  end
end
