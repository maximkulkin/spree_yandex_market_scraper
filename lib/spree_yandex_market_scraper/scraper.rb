# encoding: utf-8

require 'uri'

class SpreeYandexMarketScraper::Scraper
  MARKET_BASE_URL = "http://market.yandex.ru"
  META_SUFFIX = '. Все характеристики, сравнение цен, отзывы покупателей на Яндекс.Маркете.'

  def self.scrap(modelid)
    if %r{^http://} =~ modelid
      given_uri = URI.parse(modelid)
      given_uri_params = given_uri.query.split('&').each_with_object({}) do |s, params|
        k, v = s.split('=', 2)
        params[k] = v
      end

      modelid = given_uri_params['modelid']
    end

    info_page_link = MARKET_BASE_URL + "/model.xml?modelid=#{modelid}"
    info_page = Nokogiri.HTML(open(info_page_link), info_page_link)

    title = info_page.at_css('h1.b-page-title').text
    description = info_page.css('.b-model-friendly ul li').map(&:text).join('; ').capitalize
    meta_description = info_page.at_xpath('//meta[@name="Description"]/@content').text.sub(META_SUFFIX, '')

    images = []
    %w{big small}.each do |size|
      info_page.css("#model-pictures .b-model-pictures__#{size}").each do |e|
        image_link = e.at_css('a').attr('href') rescue nil
        images << image_link if image_link
      end
    end


    properties_page_link = MARKET_BASE_URL + "/model-spec.xml?modelid=#{modelid}"
    properties_page = Nokogiri.HTML(open(properties_page_link), properties_page_link)

    current_property_group = ''
    properties = []
    properties_page.css('table.b-properties tr').each do |row|
      if property_group_title = row.at_css('th.b-properties__title')
        current_property_group = property_group_title.text
      else
        property_name = row.at_css('th.b-properties__label').text
        property_value = row.at_css('td.b-properties__value').text
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
end

