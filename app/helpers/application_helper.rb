# frozen_string_literal: true

module ApplicationHelper

  def body_css_classes
    classes = []
    if current_site&.configuration&.engine_overrides&.any?
      classes.push(Rails.configuration.gobierto_engines_themes[current_site.configuration.engine_overrides.first])
    end
    classes.push controller_name
    classes.push action_name
    classes.push "#{controller_name}_#{action_name}"
    classes.push "#{controller_path}_#{action_name}".tr("/", "_")
    classes.join(" ")
  end

  def render_if_exists(partial_path, partial_params = {}, format = "html.erb")
    partial_path_name = Pathname.new(partial_path)
    partial_file_name = "#{partial_path_name.dirname}/_#{partial_path_name.basename}.#{format}"

    render(partial_path, partial_params) if lookup_context.exists?(partial_file_name)
  end

  def localized_enum(class_name, enum_name)
    return {} unless class_name.respond_to?(enum_name.to_s.pluralize)

    class_name.send(enum_name.to_s.pluralize).reduce({}) do |enum_options, (key, _)|
      enum_options.merge!(
        I18n.t("activerecord.attributes.#{class_name.model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{key}", default: key.capitalize) => key
      )
    end
  end

  def privacy_policy_page_link
    if current_site&.configuration&.privacy_page?
      link_to t("layouts.accept_privacy_policy_signup"), gobierto_cms_page_or_news_path(current_site.configuration.privacy_page)
    end
  end

  def tab_attributes(condition)
    { role: "tab", "tabindex" => condition ? 0 : -1, "aria-selected" => condition }
  end

  def show_social_links?
    !params[:controller].include?("user/")
  end

  def full_layout?
    (controller_name == "contribution_containers" && action_name == "show") || (controller_name == "poll_answers" && action_name == "new")
  end

  def filetype_icon(attachment)
    extension = attachment_extension(attachment)
    fontawesome_filetype = if ::GobiertoAttachments::Attachment.extension_fontawesome_matching.has_key?(extension)
                             "-" + ::GobiertoAttachments::Attachment.extension_fontawesome_matching[extension]
                           else
                             ""
                           end
    html = "<i class='fas fa-file" + fontawesome_filetype + "-o'></i>"
    html.html_safe
  end

  def image_extension?(attachment)
    ::GobiertoAttachments::Attachment.extension_fontawesome_matching[attachment_extension(attachment)] == "image"
  end

  def attachment_extension(attachment)
    if attachment.class == String
      attachment.split(".").last
    else
      attachment.extension
    end.to_sym
  end

  def current_parameters_with_year(year)
    params.except(:host, :port, :protocol).merge(year: year).permit!
  end

  def content_for_if(name, condition, &block)
    if condition
      content_for(name, &block)
    end
    yield
  end

  def attribute_indication_tag(params = {})
    text = if params[:required] && params[:max_length]
             I18n.t "views.forms.required_and_max_characters", length: parse_max_length(params[:max_length])
           elsif params[:required]
             I18n.t "views.forms.required"
           elsif params[:max_length]
             I18n.t "views.forms.max_characters", length: parse_max_length(params[:max_length])
           end
    content_tag(:span, class: "indication") { text }
  end

  def whom(entity_name)
    if I18n.locale == :ca
      if /\A[aeiou]/i.match? entity_name
        " l'#{entity_name}"
      else
        # TODO: define a setting with the genre of the entity
        "la #{entity_name}"
      end
    else
      " " + entity_name
    end
  end

  def meaningful_date_range?(date_range, options = {})
    return false unless date_range.is_a?(Array)

    date_range.map! { |d| d.change(hour: 0, min: 0, sec: 0) } if options[:only_date]
    date_range.first != date_range.last
  end

  def simple_pluralize(count, singular, plural)
    if count == 1 || count.to_s =~ /^1(\.0+)?$/
      singular
    else
      plural
    end
  end

  def truncated_html(html_text, options)
    return "" unless html_text.present?

    stripped_text = html_text.dup

    if options[:headers] == false
      stripped_text.gsub!(/<h\d(.*?)>/, "<p>") # header opening
      stripped_text.gsub!(/<\\h\d>/, "</p>") # header closing
    end

    stripped_text.gsub!(/<img(.*?)>/, "") if options[:images] == false

    truncate_html(stripped_text, options)
  end

  private

  def parse_max_length(params)
    if params.is_a? Integer
      params
    elsif params[:length]
      params[:length]
    else
      params[:f].object.class.max_length(params[:attr])
    end
  end

end
