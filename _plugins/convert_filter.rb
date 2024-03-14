module ConvertFilterHelper
  def self.convert(context, input, source_extension, destination_extension = nil)
    # Get the site's converters
    converters = context.registers[:site].converters

    # Determine the destination extension (if not provided)

    destination_extension ||= begin
      path = context.registers[:page]["path"]
      path_ext = File.extname(path)

      if path_ext.empty?
        path || "html"
      else
      "." + path_ext
      end
    end


    if source_extension == destination_extension
      # If source and destination extensions are the same, return input as-is
      input
    else
      # Find the converter for the given source and destination extensions
      converter = converters.find { |c| c.matches(source_extension) && c.output_ext(source_extension) == ".html" }

      if converter
        # Convert the input using the found converter
        converter.convert(input)
      else
        # No converter found for the given extensions
        raise ArgumentError, "No converter available for source extension '#{source_extension}' to '#{destination_extension}'"
      end
    end
  end
end

module Jekyll
  module ConvertFilter
    def convert(input, source_extension, destination_extension = nil)
      ConvertFilterHelper.convert(@context, input, source_extension, destination_extension)
    end
  end
end

# Register the filter
Liquid::Template.register_filter(Jekyll::ConvertFilter)