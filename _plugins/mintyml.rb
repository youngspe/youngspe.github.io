

require 'open3'

module Jekyll

  class MintymlConverter < Converter
    self.highlighter_prefix "<[raw##["
    self.highlighter_suffix "]##]>"
    def source_root
      return @source_root if @source_root
      current_dir = __dir__

      # Traverse upwards until we reach the root directory
      while current_dir != '/'
        file_path = File.join(current_dir, 'package.json')

        return @source_root = current_dir if File.file?(file_path)

        # Move up to the parent directory
        current_dir = File.dirname(current_dir)
      end

      # If we reach the root directory and haven't found the file, return nil
      @source_root = nil
    end

    def matches(ext)
      ext =~ /^\.(mty|minty)$/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      out, err, status = Open3.capture3(
        "node #{File.join(source_root, "_node_tools/convert-mintyml.js")}",
        stdin_data: content,
      )
      puts "mintyml: #{err}" if err.length > 0
      raise err if status != 0
      out
    end

  end

end
