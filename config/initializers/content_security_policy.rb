# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data, 'fonts.googleapis.com', 'fonts.gstatic.com'
    policy.img_src     :self, :https, :data, 'res.cloudinary.com', 'cdn.tailwindcss.com'
    policy.object_src  :none
    policy.script_src  :self, :https, 'cdn.tailwindcss.com', 'js.stripe.com', 'unpkg.com'
    policy.style_src   :self, :https, :unsafe_inline, 'cdn.tailwindcss.com', 'fonts.googleapis.com'
    policy.connect_src :self, :https, 'api.stripe.com'
    policy.frame_src   'js.stripe.com', 'hooks.stripe.com'
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy in development.
  config.content_security_policy_report_only = Rails.env.development?
end
