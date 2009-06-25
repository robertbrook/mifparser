require 'rubygems'
require 'hpricot'

class MifParser

  def clean element
    element.at('text()').to_s[/`(.+)'/]
    $1.gsub('.','-')
  end

  def parse_xml xml
    doc = Hpricot.XML xml
    flow = (doc/'TextFlow').last

    stack = []
    xml = ['<Document>']
    flow.traverse_element do |element|
      case element.name
        when 'ETag'
          stack << clean(element)
          xml << '<'
          xml << stack.last
          xml << '>'
        when 'String'
          xml << clean(element)
        when 'ElementEnd'
          name = stack.pop
          xml << '</'
          xml << name
          xml << '>'
          xml << "\n" unless name[/STLords/]
      end
    end

    xml << '</Document>'
    xml.join('')
  end
end