require 'open-uri'

class Spree::Admin::YandexMarketScrapController < Spree::Admin::BaseController
  def new
    scraped_data = SpreeYandexMarketScraper::Scraper.scrap(params[:market_link])

    @title = scraped_data[:title]
    @description = scraped_data[:description]
    @meta_description = scraped_data[:meta_description]

    if params[:download_images] && !scraped_data[:images].empty?
      product = Spree::Product.find(params[:product_id])
      scraped_data[:images].each do |image_link|
        image_data = open(image_link)
        product.images.create(:attachment => image_data)
        image_data.close
      end
    end

    respond_to do |format|
      format.js
    end
  end
end

