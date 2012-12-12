# encoding: utf-8

require 'uri'

class SpreeYandexMarketScraper::Scraper
  MARKET_BASE_URL = "http://market.yandex.ru"
  META_SUFFIX = '. Все характеристики, сравнение цен, отзывы покупателей на Яндекс.Маркете.'

  def self.scrap(product_url)
    raise URI::InvalidURIError.new(product_url) unless URI.regexp([:http]) =~ product_url

    product_uri = URI.parse(product_url)
    query = product_uri.query

    info_page_url = MARKET_BASE_URL + "/model.xml?#{query}"
    info_page = Nokogiri.HTML(open(info_page_url), info_page_url)

    title = info_page.at_css('h1.b-page-title').text rescue nil
    description = info_page.css('.b-model-friendly ul li').map(&:text).join('; ').capitalize
    meta_description = info_page.at_xpath('//meta[@name="Description"]/@content').text.sub(META_SUFFIX, '') rescue nil

    images = []
    %w{big small}.each do |size|
      info_page.css("#model-pictures .b-model-pictures__#{size}").each do |e|
        image_link = e.at_css('a').attr('href') rescue nil
        next unless image_link
        image_link = MARKET_BASE_URL + image_link unless %r{^http://} =~ image_link
        images << image_link if image_link
      end
    end

    if images.empty?
      info_page.css('.b-model-pictures img').each do |e|
        image_link = e.attr('src')
        next unless image_link
        image_link = MARKET_BASE_URL + image_link unless %r{^http://} =~ image_link
        images << image_link if image_link
      end
    end

    properties_page_link = MARKET_BASE_URL + "/model-spec.xml?#{query}"
    properties_page = Nokogiri.HTML(open(properties_page_link), properties_page_link)

    current_property_group = ''
    properties = []
    properties_page.css('table.b-properties tr').each do |row|
      if property_group_title = row.at_css('th.b-properties__title')
        current_property_group = property_group_title.text
      else
        property_name = row.at_css('th.b-properties__label').text rescue nil
        property_value = row.at_css('td.b-properties__value').text rescue nil

        next unless property_name

        properties << { :group => current_property_group, :name => property_name, :value => property_value }
      end
    end

    return {
      :title => title,
      :description => description,
      :meta_description => meta_description,
      :images => images,
      :properties => properties
    }
  end

  def self.scrap_and_update(url, product)
    scraped_data = scrap(url)

    product.name = scraped_data[:title] if product.name.blank?
    product.description = scraped_data[:description] if product.description.blank?
    product.meta_description = scraped_data[:meta_description] if product.meta_description.blank?

    has_origin = Spree::Image.columns.any? { |c| c.name == 'origin' }

    image_links = Array(scraped_data[:images])
    if has_origin
      image_links.reject! { |link| product.images.any? { |i| i.origin == link } }
    elsif !product.images.empty?
      image_links = []
    end

    image_links.each do |image_link|
      image_data = open(image_link)

      image = product.images.build(:attachment => image_data)
      image.origin = image_link if has_origin
    end

    Array(scraped_data[:properties]).group_by { |d| d[:group] }.each do |group_name, properties|
      group_property_name = "=#{group_name}"
      unless product.product_properties.any? { |p| p.property_name == group_property_name }
        Spree::Property.find_by_name(group_property_name) ||
          Spree::Property.create(:name => group_property_name, :presentation => group_name)
        product.product_properties.build(:property_name => group_property_name, :value => '=') 
      end

      properties.each do |property|
        next if product.product_properties.any? { |p| p.property_name == property[:name] }

        Spree::Property.find_by_name(property[:name]) ||
          Spree::Property.create(:name => property[:name], :presentation => property[:name])
        product.product_properties.build(:property_name => property[:name], :value => property[:value])
      end
    end
  rescue URI::Error => e
    Rails.logger.error "\e[1;31mError: #{e}\e[0m"

    def product.valid?(context = nil)
      errors[:base] = I18n.t('yandex_market.error.uri')
      false
    end
  rescue OpenURI::HTTPError => e
    Rails.logger.error "\e[1;31mError: #{e}\e[0m"

    def product.valid?(context = nil)
      errors[:base] = I18n.t('yandex_market.error.load')
      false
    end
  rescue Object => e
    Rails.logger.error "\e[1;31mError: #{e}\e[0m"

    def product.valid?(context = nil)
      errors[:base] = I18n.t('yandex_market.error.parse')
      false
    end
  end


  def self.search(text, options = {})
    limit = options[:limit]

    search_url = "#{MARKET_BASE_URL}/search.xml?text=#{URI.escape(text)}"
    search_page = Nokogiri.HTML(open(search_url), search_url)

    base_uri = URI.parse(search_url)
    
    offers = []
    search_page.css('.b-offers').each do |offer_elem|
      break if limit && offers.size >= limit

      begin
        url = URI.parse(offer_elem.at_css('h3.b-offers__title a.b-offers__name').attr('href'))
        next unless url.path == '/model.xml'

        url = base_uri.merge(url).to_s

        title = offer_elem.at_css('h3.b-offers__title a.b-offers__name').text

        image_url = offer_elem.at_css('img.b-offers__img').attr('src') rescue nil
        description = offer_elem.css('p.b-offers__spec').collect(&:text).compact.join("\n")
        offers << {
          :url => url,
          :title => title,
          :description => description,
          :image => image_url
        }
      rescue
        Rails.logger.error "\e[1;31mError: couldn't parse search result, #{e}\e[0m"
      end
    end

    offers
  end
end

