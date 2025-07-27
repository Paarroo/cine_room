module ImageHelper
  def safe_image_tag(attachment, options = {})
    if attachment&.attached?
      image_tag(attachment, options)
    else
      placeholder_image(options)
    end
  end

  def safe_image_url(attachment)
    if attachment&.attached?
      url_for(attachment)
    else
      nil
    end
  end

  private

  def placeholder_image(options = {})
    css_classes = options[:class] || ""
    alt_text = options[:alt] || "Image placeholder"
    
    content_tag :div, 
                class: "#{css_classes} bg-gradient-to-br from-slate-600 to-slate-800 flex items-center justify-center",
                style: options[:style] do
      content_tag :span, "🎬", class: "text-4xl opacity-50"
    end
  end
end