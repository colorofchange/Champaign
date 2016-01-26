class LiquidRenderer
  include Rails.application.routes.url_helpers

  def initialize(page, layout:, location: nil, member: nil, url_params: {})
    @page = page
    @layout = layout
    @location = location
    @member = member
    @url_params = url_params
  end

  def render
    Rails.cache.fetch(cache.key_for_markup) do
      template.render( markup_data ).html_safe
    end
  end

  def template
    @template ||= Liquid::Template.parse(@layout.content)
  end

  def markup_data
    return @markup_data if @markup_data

    @markup_data = Rails.cache.fetch( cache.key_for_data ) do
      {
        images: images,
        primary_image: image_urls(@page.image_to_display),
        shares: Shares.get_all(@page),
        follow_up_url: follow_up_page_path(@page.id),
        outstanding_fields: outstanding_fields(plugin_data),
        donation_bands: donation_bands(plugin_data)
      }.
      merge( @page.liquid_data ).
      merge( LiquidHelper.globals(page: @page) )
    end.merge( plugin_data ).deep_stringify_keys
  end

  def data
    markup_data.merge(member_data)
  end

  def images
    @page.images.map{ |img| image_urls(img) }
  end

  private

  def plugin_data
    @plugin_data ||= Plugins.data_for_view(@page, {form_values: @member.try(:attributes), donation_band: @url_params[:donation_band]})
  end

  def member_data
    {
      url_params: @url_params,
      member:     @member.try(:liquid_data),
      location:   location
    }.deep_stringify_keys
  end

  def outstanding_fields(plugin_data)
    isolate_from_plugin_data(plugin_data, :outstanding_fields)
  end

  def donation_bands(plugin_data)
    isolate_from_plugin_data(plugin_data, :donation_bands).first
  end

  def isolate_from_plugin_data(plugin_data, field)
    plugin_values = plugin_data.deep_symbolize_keys[:plugins].values().map(&:values).flatten
    plugin_values.map{|plugin| plugin[field]}.flatten.compact
  end

  def location
    return @location if @location.blank?
    country_code = if @member.try(:country) && @member.country.length == 2
      @member.country
    else
      @location.country_code
    end
    return @location.data if country_code.blank?
    currency = Donations::Utils.currency_from_country_code(country_code)
    @location.data.merge(currency: currency)
  end

  def set_locale
    begin
      I18n.locale = @page.language.code if @page.language.present?
    rescue I18n::InvalidLocale
      # by setting the +i18n.enforce_available_locales+ flag to true but
      # catching the resulting error, it allows us to only set the locale
      # if it's one explicitly registered under +i18n.available_locales+
    end
  end

  def image_urls(img)
    return { urls: { large: '', small: '' } } if img.blank? || img.content.blank?
    { urls: { large: img.content.url(:large), small: img.content.url(:thumb) } }
  end

  def cache
    @cache ||= Cache.new(@page, @layout)
  end

  class Cache
    def initialize(page, layout)
      @page   = page
      @layout = layout
    end

    def key_for_data
      "client_data:" << base
    end

    def key_for_markup
      "liquid_markup:#{last_partial.try(:cache_key)}:#{base}"
    end

    private

    def last_partial
      @liquid_partial ||= LiquidPartial.for_cache_key.first
    end

    def base
      "#{@page.cache_key}:#{@layout.try(:cache_key)}"
    end
  end
end

