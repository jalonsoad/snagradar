# Replace Rails' default `<div class="field_with_errors">…</div>` wrapper with
# an inline approach that (1) adds Tailwind error styling to the invalid field
# itself and (2) appends a <small> with the first error message right under it.
#
# Pattern taken from https://medium.com/@yamenmari/ (field_error_proc article).

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  doc     = Nokogiri::HTML.fragment(html_tag)
  element = doc.children.first
  tag     = element&.name&.downcase

  # Skip non-field tags (e.g. <label>) and elements without an error message
  unless %w[input select textarea].include?(tag)
    next html_tag.html_safe
  end

  error_text = Array(instance.error_message).first
  next html_tag.html_safe if error_text.blank?

  # Don't paint the "interest" radios or the "terms_accepted" checkbox — they
  # already render inside styled wrappers; show the message only.
  is_choice = element["type"].to_s.match?(/\A(radio|checkbox)\z/)

  unless is_choice
    extra_classes  = "border-rose-500 focus:border-rose-500 focus:ring-rose-500 focus:outline-rose-500"
    element["class"] = [element["class"], extra_classes].compact.join(" ")
  end

  field_html = doc.to_html

  message_html =
    %(<small class="mt-1.5 flex items-center gap-1 text-xs font-medium text-rose-600">) +
    %(<svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>) +
    ERB::Util.html_escape(error_text) +
    %(</small>)

  (field_html + message_html).html_safe
end
