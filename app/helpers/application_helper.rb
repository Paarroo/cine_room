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
  def safe_movie_title(movie)
      safe_attr(movie, :title, 'Film sans titre')
    end

    def safe_movie_director(movie)
      safe_attr(movie, :director, 'Réalisateur inconnu')
    end

    def safe_movie_creator(movie)
      return 'Utilisateur inconnu' if movie.nil? || movie.user.nil?
      safe_attr(movie.user, :full_name, 'Utilisateur sans nom')
    end

    def movie_status_badge(movie)
      status = safe_attr(movie, :validation_status, 'pending')

      case status.to_s
      when 'pending'
        content_tag :span, class: "px-3 py-1 bg-yellow-500/20 text-yellow-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-clock mr-1"></i>En attente'.html_safe
        end
      when 'approved'
        content_tag :span, class: "px-3 py-1 bg-green-500/20 text-green-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-check mr-1"></i>Validé'.html_safe
        end
      when 'rejected'
        content_tag :span, class: "px-3 py-1 bg-red-500/20 text-red-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-times mr-1"></i>Rejeté'.html_safe
        end
      else
        content_tag :span, class: "px-3 py-1 bg-gray-500/20 text-gray-300 rounded-full text-xs font-medium" do
          '<i class="fas fa-question mr-1"></i>Inconnu'.html_safe
        end
      end
    end
    def number_to_percentage(number, options = {})
      precision = options[:precision] || 0
      "#{number.round(precision)}%"
    end
end
