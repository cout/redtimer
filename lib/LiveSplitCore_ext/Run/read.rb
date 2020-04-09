require 'LiveSplitCore'

class LiveSplitCore::Run
  def self.read(filename)
    File.open(filename) do |f|
      LiveSplitCore::Run.parse_file_handle(f.fileno, '', false).with do |result|
        raise "Unable to parse splits file `#{filename}'" if not result.parsed_successfully
        return result.unwrap
      end
    end
  end
end
