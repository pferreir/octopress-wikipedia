require 'json'
require 'nokogiri'

def unquoted_string(text)
  if text =~ Liquid::QuotedString
    return text.strip[1..-2]
  elsif ['true', 'false'].index(text)
    return text == 'true'
  elsif text =~ /^[-+]?[0-9]+$/
    text.to_i
  else
    text
  end
end

module Jekyll
  class WikipediaTag < Liquid::Tag
    Syntax = /^\s*([\w\'\"\s]*?[\w\'\"])(?:\s(\s*#{Liquid::TagAttributes}\s*)(,\s*#{Liquid::TagAttributes}\s*)*)?\s*$/o

    def initialize(tag_name, markup, token)
      super
      @attributes = { :lang => "en"}

      if markup =~ Syntax
        @text = unquoted_string $1.strip

        markup.scan(Liquid::TagAttributes) do |key, value|
          @attributes[key.to_sym] = unquoted_string(value)
        end
      end

      @cache_disabled = false
      @cache_folder   = File.expand_path "../.wikipedia-cache", File.dirname(__FILE__)
      FileUtils.mkdir_p @cache_folder
    end

    def render(context)
      html_output_for(get_cached_article(@text) || get_article_from_web(@text))
    end

    def wiki_url()
      "http://%{lang}.wikipedia.org" % @attributes
    end

    def html_output_for(data)
      tpl_data = ""
      File.open(File.expand_path "wikipedia.html", File.dirname(__FILE__)) do |io|
        tpl_data = io.read
      end
      data[:config] = @attributes
      Liquid::Template.parse(tpl_data).render(data)
    end

    def extract_metadata(doc, name)
      def_html = cleanup doc

      image_parent = ['.infobox_v2', '.infobox', '.thumb'].find do |container|
        !doc.css(container + ' img').empty?
      end

      full_name = def_html.css('strong')[0].text
      image = image_parent ? doc.css(image_parent + ' img')[0]['src'] : nil

      {
        "code" => def_html.to_html,
        "img_url" => image,
        "wikipedia_url" => wiki_url + "/wiki/" + name,
        "article_name" => full_name
      }
    end

    def get_article_from_web(name)
      raw_uri = URI.parse "#{wiki_url}/w/api.php?action=query&titles=#{CGI.escape(name)}&rvprop=content&prop=revisions&format=json&rvparse=&redirects"
      http    = Net::HTTP.new raw_uri.host, raw_uri.port
      request = Net::HTTP::Get.new raw_uri.request_uri

      data    = http.request request
      data    = data.body

      html = ""
      pages = JSON.parse(data)['query']['pages']

      pages.each { |_, page| html = page['revisions'][0]['*'] }

      doc = Nokogiri::HTML::DocumentFragment.parse html
      data = extract_metadata doc, name

      cache name, data unless @cache_disabled
      data
    end

    def cleanup(doc)
      description = doc.xpath("./p")[0]
      ['.unicode', '.reference', '.noprint', 'img[alt=play]'].each do |cls|
        description.css(cls).each { |node| node.replace(' ') }
      end

      description.css('b').each do |node|
        node.replace("<strong>%s</strong>" % node.content.to_html)
      end

      description.css('.IPA').each do |node|
        node.content = node.text
      end

      description.css('a').each do |node|
        node['href'] = wiki_url + node['href'] if /^\/wiki\//.match(node['href'])
      end

      description
    end

    def get_cached_article(article)
      return nil if @cache_disabled

      cache_file = get_cache_file_for article, @attributes[:lang]
      JSON.parse(File.read cache_file) if File.exist? cache_file
    end

    def cache(article, data)
      cache_file = get_cache_file_for article, @attributes[:lang]

      File.open(cache_file, "w") do |io|
        io.write JSON.generate data
      end
    end

    def get_cache_file_for(article, lang)
      bad_chars = /[^a-zA-Z0-9\-_.]/
      article   = article.gsub bad_chars, ''
      md5       = Digest::MD5.hexdigest "#{article}"

      File.join @cache_folder, "#{article}.#{lang}.cache"
    end
  end
end

Liquid::Template.register_tag('wikipedia', Jekyll::WikipediaTag)
