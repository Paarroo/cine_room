# Helper for GDPR cookie consent management
module CookieConsentHelper
  # Check if user has given consent for cookies
  def cookie_consent_given?
    cookies[:cookie_consent] == 'true'
  end

  # Check if user has consented to analytics cookies
  def analytics_consent_given?
    cookies[:analytics_consent] == 'true'
  end

  # Check if user has consented to marketing cookies
  def marketing_consent_given?
    cookies[:marketing_consent] == 'true'
  end

  # Check if user has made any cookie choice
  def cookie_choice_made?
    cookies[:cookie_consent].present?
  end

  # Render analytics scripts only if consent is given
  def render_analytics_scripts
    return unless analytics_consent_given?
    
    # Add your Google Analytics or other analytics scripts here
    content_for :head do
      raw <<~HTML
        <!-- Google Analytics (only if consent given) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
        <script>
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', 'GA_MEASUREMENT_ID', {
            'anonymize_ip': true,
            'cookie_flags': 'SameSite=Lax;Secure'
          });
        </script>
      HTML
    end
  end

  # Render marketing scripts only if consent is given
  def render_marketing_scripts
    return unless marketing_consent_given?
    
    # Add your marketing/advertising scripts here
    content_for :head do
      raw <<~HTML
        <!-- Facebook Pixel (only if consent given) -->
        <script>
          !function(f,b,e,v,n,t,s)
          {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
          n.callMethod.apply(n,arguments):n.queue.push(arguments)};
          if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
          n.queue=[];t=b.createElement(e);t.async=!0;
          t.src=v;s=b.getElementsByTagName(e)[0];
          s.parentNode.insertBefore(t,s)}(window, document,'script',
          'https://connect.facebook.net/en_US/fbevents.js');
          fbq('init', 'YOUR_PIXEL_ID');
          fbq('track', 'PageView');
        </script>
      HTML
    end
  end

  # Generate cookie consent data for JavaScript
  def cookie_consent_data
    {
      essential: true,
      analytics: analytics_consent_given?,
      marketing: marketing_consent_given?,
      choice_made: cookie_choice_made?
    }.to_json.html_safe
  end

  # Cookie consent status for admin interface
  def cookie_consent_status
    if !cookie_choice_made?
      { status: 'pending', message: 'Aucun choix effectué', class: 'text-yellow-500' }
    elsif cookie_consent_given?
      { status: 'accepted', message: 'Cookies acceptés', class: 'text-green-500' }
    else
      { status: 'declined', message: 'Cookies non-essentiels refusés', class: 'text-red-500' }
    end
  end

  # Consent banner classes for different states
  def consent_banner_classes
    base_classes = "fixed bottom-0 left-0 right-0 bg-gray-900 border-t border-gray-700 p-4 z-50"
    
    if cookie_choice_made?
      "#{base_classes} hidden"
    else
      "#{base_classes} transform translate-y-full transition-transform duration-300 ease-in-out"
    end
  end

  # Generate structured data for cookie policy
  def cookie_policy_structured_data
    {
      "@context": "https://schema.org",
      "@type": "WebPage",
      "name": "Politique de Cookies",
      "description": "Informations sur l'utilisation des cookies sur ce site web",
      "url": "#{request.base_url}/privacy",
      "inLanguage": "fr-FR",
      "isPartOf": {
        "@type": "WebSite",
        "name": "CinéRoom",
        "url": request.base_url
      }
    }.to_json.html_safe
  end

  # Check if we should show the consent banner
  def show_consent_banner?
    !cookie_choice_made? && !current_page?(privacy_path)
  end

  # Cookie categories for settings
  def cookie_categories
    [
      {
        name: 'Essentiels',
        key: 'essential',
        description: 'Ces cookies sont nécessaires au fonctionnement du site web et ne peuvent pas être désactivés.',
        always_active: true,
        examples: ['Cookies de session', 'Cookies de sécurité', 'Cookies d\'équilibrage de charge']
      },
      {
        name: 'Analyse',
        key: 'analytics', 
        description: 'Ces cookies nous aident à comprendre comment les visiteurs interagissent avec notre site web.',
        always_active: false,
        examples: ['Google Analytics', 'Suivi des pages vues', 'Analyse du comportement utilisateur']
      },
      {
        name: 'Marketing',
        key: 'marketing',
        description: 'Ces cookies sont utilisés pour vous proposer des publicités plus pertinentes.',
        always_active: false,
        examples: ['Facebook Pixel', 'Ciblage publicitaire', 'Suivi des conversions']
      }
    ]
  end

  # Legal compliance check
  def gdpr_compliant?
    cookie_choice_made? || show_consent_banner?
  end

  # Generate privacy notice text
  def privacy_notice_text
    "Nous utilisons des cookies pour améliorer votre expérience de navigation, vous proposer un contenu personnalisé et analyser notre trafic. " \
    "En cliquant sur 'Tout Accepter', vous acceptez notre utilisation des cookies. " \
    "Vous pouvez gérer vos préférences ou en savoir plus dans notre politique de confidentialité."
  end

  # Cookie management page link
  def cookie_settings_link
    link_to 'Gérer les cookies', '#', 
            onclick: 'CookieConsent.showSettings(); return false;',
            class: 'text-blue-400 hover:text-blue-300 underline'
  end

  # Revoke consent link (for footer or settings page)
  def revoke_consent_link
    link_to 'Révoquer le consentement aux cookies', '#',
            onclick: 'CookieConsent.revokeConsent(); return false;',
            class: 'text-red-400 hover:text-red-300 underline text-sm'
  end
end