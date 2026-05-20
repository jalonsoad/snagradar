module IconHelper
  # Inlines an Icons8 SVG from app/assets/images/icons/ so that
  # `fill="currentColor"` inherits the surrounding text-* utility.
  #
  #   <%= icon "plumbing", class: "h-6 w-6 text-talent-orange" %>
  #
  # The file is read once per process and cached.
  ICON_DIR  = Rails.root.join("app", "assets", "images", "icons").freeze
  ICON_CACHE = {}

  def icon(name, class: "h-5 w-5", aria_label: nil)
    klass = binding.local_variable_get(:class)
    raw   = ICON_CACHE[name] ||= File.read(ICON_DIR.join("#{name}.svg")).strip

    a11y = aria_label ? %(role="img" aria-label="#{ERB::Util.html_escape(aria_label)}") : %(aria-hidden="true" focusable="false")

    # Inject class + a11y attrs into the root <svg> tag.
    svg = raw.sub(/<svg\b/, %(<svg class="#{klass}" #{a11y}))
    svg.html_safe
  rescue Errno::ENOENT
    # Fail loudly in dev, silently in production
    raise "Missing icon: #{name}.svg" if Rails.env.development?
    "".html_safe
  end
end
