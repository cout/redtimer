require 'LiveSplitCore'

module LiveSplitCore_ext; end

class LiveSplitCore_ext::ColumnView
  def initialize(splits, segment_idx, col_idx)
    @splits = splits
    @segment_idx = segment_idx
    @col_idx = col_idx
  end

  def value
    @splits.column_value(@segment_idx, @col_idx)
  end

  def semantic_color
    @splits.column_semantic_color(@segment_idx, @col_idx)
  end
end

class LiveSplitCore_ext::SegmentView
  include Enumerable

  def initialize(splits, segment_idx)
    @splits = splits
    @segment_idx = segment_idx
  end

  def each_column
    if block_given? then
      for col_idx in (0...length) do
        yield self[col_idx]
      end
    else
      to_enum(:each)
    end
  end

  def each(&block)
    each_column(&block)
  end

  def length
    @splits.columns_len(@segment_idx)
  end

  def name
    @splits.name(@segment_idx)
  end

  def [](col_idx)
    LiveSplitCore_ext::ColumnView.new(@splits, @segment_idx, col_idx)
  end

  def current_split?
    @splits.is_current_split(@segment_idx)
  end
end

class LiveSplitCore::SplitsComponentStateRef
  include Enumerable

  def each_segment
    if block_given? then
      for i in (0...self.len) do
        yield name(i), segment(i)
      end
    else
      to_enum(:each)
    end
  end

  def each(&block)
    each_segment(&block)
  end

  def segment(idx)
    LiveSplitCore_ext::SegmentView.new(self, idx)
  end
end
