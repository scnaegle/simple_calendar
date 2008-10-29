# SimpleCalendar
#
# Form Builder
class SimpleCalendarFormBuilder < ActionView::Helpers::FormBuilder
  helpers = field_helpers +
            %w(datetime_select) - 
            %w(hidden_field label fields_for)

  helpers.each do |name|
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}
      label = label(field, options[:label], :class => options[:label_class])
      @template.content_tag(:p, @template.content_tag(:b, label) + ":<br/>" + super)
    end
  end
end
 
ActionController::Base.class_eval do
  # For Rails versions greater than 2.1 
  self.append_view_path File.join(File.dirname(__FILE__), '..', 'app', 'views')
end

ActionView::Base.class_eval do
  alias render_other render
  def render(options = {}, local_assigns = {}, &block) #:nodoc:
    if options.is_a?(Hash) and options[:simple_calendar]
      render_simple_calendar(options, local_assigns, &block)
    else
      render_other(options, local_assigns, &block)
    end
  end

  def render_simple_calendar(options = {}, local_assigns = {}, &block)
    @admin = options[:admin] || false
    session[:simple_calendar_admin] = @admin

    @prefix = options[:prefix] || session[:simple_calendar_prefix] || ""
    session[:simple_calendar_prefix] = @prefix

    @mode  = options[:mode] || 'month'
    @layout = options.has_key?(:layout) ? options[:layout] : true
    @date  = Date.today 
    if !params[:date].nil?
      @year, @month, @day = params[:date].to_s.split("-")
      @year = @year.to_i
      @month = @month.to_i
      @day = @mode == 'month' ? @date.day.to_i : @day.to_i
    else
      @day   = (options[:day]   || @date.day).to_i
      @year  = (options[:year]  || @date.year).to_i
      @month = (options[:month] || @date.month).to_i
    end
    @date  = Date.new(@year, @month, @day)
    @days  = Time.days_in_month(@month, @year)    
    #@base  = options[:base]

    @first_week_day = (@date - @date.day.days + 1.day).wday
    @calendar_path = options[:return_to] || session[:simple_calendar_path] || ""
    @calendar_name = options[:simple_calendar] || "default_simple_calendar"
    @simple_calendar = SimpleCalendar.find_or_create_by_name(@calendar_name)
    session[:simple_calendar_name] = @calendar_name
    session[:simple_calendar_path] = @calendar_path
    @entries = @simple_calendar.simple_calendar_entries.
                all_by_month_and_year(@month, @year).
                group_by(&:date)

    if @layout
      render :partial => 'shared/calendar'
    else
      if @mode == 'day'
        render :partial => 'shared/day'
      else
        render :partial => 'shared/simple_calendar'
      end
    end
  end
end
