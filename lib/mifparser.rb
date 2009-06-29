require 'tempfile'
require 'rubygems'
require 'hpricot'

class MifParser

  VERSION = "0.0.0"

  def clean element
    element.at('text()').to_s[/`(.+)'/]
    $1.gsub('.','-')
  end

  # e.g. parser.parse("pbc0930106a.mif")
  def parse mif_file
    xml_file = Tempfile.new("#{mif_file}.xml",'.')
    xml_file.close # was open
    Kernel.system "mif2xml < #{mif_file} > #{xml_file.path}"
    result = parse_xml_file(xml_file.path)
    xml_file.delete
    result
  end

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file
    parse_xml IO.read(xml_file)
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
          xml << "\n" unless name[/(Day|STHouse|STLords|STText)/]
      end
    end

    xml << '</Document>'
    xml.join('')
  end
end