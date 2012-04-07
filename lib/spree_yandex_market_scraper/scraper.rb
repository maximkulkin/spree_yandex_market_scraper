# encoding: utf-8

require 'uri'

class SpreeYandexMarketScraper::Scraper
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

    link = "http://market.yandex.ru/model.xml?modelid=#{modelid}"
    product_page = Nokogiri.HTML(open(link), link)

    title = product_page.at_css('h1.b-page-title').text
    description = product_page.at_css('.b-model-friendly ul').text

    images = []
    %w{big small}.each do |size|
      product_page.css("#model-pictures .b-model-pictures__#{size}").each do |e|
        image_link = e.at_css('a').attr('href') rescue nil
        images << image_link if image_link
      end
    end

    meta_description = product_page.at_xpath('//meta[@name="Description"]/@content').text.sub(META_SUFFIX, '')

    return {
      :title => title,
      :description => description,
      :images => images,
      :meta_description => meta_description
    }
  end
end

