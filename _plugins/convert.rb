module Jekyll
  class ConvertBlock < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @args = markup.split(' to ').map { |s| s.strip }
    end

    def render(context)
      ConvertFilterHelper.convert(context, super, *@args)
    end
  end
end

Liquid::Template.register_tag('convert', Jekyll::ConvertBlock)
