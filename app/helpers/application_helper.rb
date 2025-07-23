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
end
