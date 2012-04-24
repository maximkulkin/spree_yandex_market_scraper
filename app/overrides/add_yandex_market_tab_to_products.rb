Deface::Override.new(
  :name => 'add_yandex_market_tab',
  :virtual_path => 'spree/admin/shared/_product_tabs',
  :insert_bottom => 'ul[data-hook=admin_product_tabs]',
  :text => "
    <li<%== ' class=\"active\"' if current == 'YandexMarketInfo' %>>
      <%= link_to t('yandex_market.market'), edit_admin_product_yandex_market_info_url(@product) %>
    </li>
  ",
  :original => '3801430748a019ba9c003cdf356289c7f9d98724'
)

