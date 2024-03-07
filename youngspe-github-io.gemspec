Gem::Specification.new do |spec|
    spec.name          = "youngspe.github.io"
    spec.version       = "1.0.0"
    spec.authors       = ["Spencer Young"]
    # spec.email         = ["someone@example.com"]

    spec.summary       = "My personal site"

    spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(assets|_layouts|_includes|LICENSE|README|feed|404|_data|tags|staticman)}i) }

    spec.add_runtime_dependency "jekyll", "~> 4.3"
    spec.add_runtime_dependency "jekyll-paginate", "~> 1.1"
    spec.add_runtime_dependency "jekyll-sitemap", "~> 1.4"
    spec.add_runtime_dependency "kramdown-parser-gfm", "~> 1.1"
    spec.add_runtime_dependency "kramdown", "~> 2.4.0"
    spec.add_runtime_dependency "tomlrb", ">= 2.0"

    spec.add_development_dependency "bundler", ">= 1.16"
    spec.add_development_dependency "rake", "~> 13.0"
  end
