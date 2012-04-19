Spree::Admin::ProductsController.class_eval do
  create.before :scrap_product_data_from_yandex_market

  def scrap_product_data_from_yandex_market
    return if params[:yandex_market_link].blank?

    begin
      scraped_data = SpreeYandexMarketScraper::Scraper.scrap(params[:yandex_market_link])

      @product.name = scraped_data[:title] if @product.name.blank?
      @product.description = scraped_data[:description] if @product.description.blank?
      @product.meta_description = scraped_data[:meta_description] if @product.meta_description.blank?

      Array(scraped_data[:images]).each do |image_link|
        @product.images.build(:attachment => open(image_link))
      end

      Array(scraped_data[:properties]).each do |property|

      end
    rescue OpenURI::HTTPError => e
      logger.error e
      def @product.valid?(context = nil)
        errors[:base] = I18n.t('yandex_market.error.load')
        false
      end
    rescue Object => e
      logger.error e
      def @product.valid?(context = nil)
        errors[:base] = I18n.t('yandex_market.error.parse')
        false
      end
    end
  end
end
