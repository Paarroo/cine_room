module ApplicationHelper
  def safe_id(object, default = 0)
    object&.id || default
  end

  def safe_attr(object, attribute, default = '')
    return default if object.nil?
    object.respond_to?(attribute) ? object.send(attribute) : default
  end

  def safe_render(partial, locals = {})
    object = locals[:object] || locals.values.first
    return '' if object.nil?
    render partial, locals
  rescue => e
    Rails.logger.error "Safe render error: #{e.message}"
    ''
  end

  def safe_each(collection, &block)
    return [] if collection.nil? || !collection.respond_to?(:each)
    collection.compact.each(&block)
  end

  def safe_count(collection)
    return 0 if collection.nil?
    collection.respond_to?(:count) ? collection.count : 0
  end

  def safe_present?(object)
    object&.present? || false
  end
    def number_to_percentage(number, options = {})
      precision = options[:precision] || 0
      "#{number.round(precision)}%"
    end

    # Convert price from cents to euros and format as currency
    def display_price(price_cents, options = {})
      return '0 €' if price_cents.nil? || price_cents.zero?
      
      euros = price_cents / 100.0
      precision = options[:precision] || 2
      unit = options[:unit] || '€'
      
      number_to_currency(euros, unit: unit, precision: precision)
    end

    # Calculate total price for participation (price_cents * seats converted to euros)
    def calculate_participation_total(event, seats)
      return 0 if event.nil? || event.price_cents.nil? || seats.nil?
      
      total_cents = event.price_cents * seats.to_i
      total_cents / 100.0
    end
end
