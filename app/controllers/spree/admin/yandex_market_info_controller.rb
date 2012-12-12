class Spree::Admin::YandexMarketInfoController < Spree::Admin::BaseController
  before_filter :load_data

  def edit
    @search_text = params[:product_name] || @product.name
    @offers = SpreeYandexMarketScraper::Scraper.search(@search_text, :limit => 5)
  end

  def update
    SpreeYandexMarketScraper::Scraper.scrap_and_update(params[:yandex_market_link], @product)

    property_count = @product.product_properties.size
    @product.product_properties.reject! { |p| p.value.length > 255 }
    if property_count != @product.product_properties.size
      flash[:error] = I18n.t(:'yandex_market.error.long_property_value') 
    end

    if @product.save
      @product.images.each { |i| i.save }
      flash.notice = flash_message_for(@product, :successfully_updated)
      redirect_to edit_admin_product_url(@product)
    else
      edit
      render :action => 'edit'
    end
  end

  private

  def load_data
    @product = Spree::Product.find_by_permalink(params[:product_id])
  end
end
