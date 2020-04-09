require 'LiveSplitCore'

class LiveSplitCore::LayoutStateRef
  include Enumerable

  def each
    for i in (0...self.len) do
      type = component_type(i)
      component = case type
        when 'Title' then component_as_title(i)
        when 'Splits' then component_as_splits(i)
        when 'Timer' then component_as_timer(i)
        when 'KeyValue' then component_as_key_value(i)
      end
      yield type, component
    end
  end
end
