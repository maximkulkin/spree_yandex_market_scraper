Deface::Override.new(
  :virtual_path => 'spree/admin/products/new',
  :name => 'scrap_controls',
  :insert_before => '[data-hook="new_product_attrs"]',
  :partial => 'shared/scrap_controls'
)
