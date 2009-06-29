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

  def is_instructions?(flow)
    instruction_regexp = /(`Header'|REISSUE|Running H\/F|line of text which is to be numbered|Use the following fragment to insert an amendment line number)/
    flow.inner_text[instruction_regexp] ||
    (flow.at('PgfTag') && flow.at('PgfTag/text()').to_s[/AmendmentLineNumber/])
  end

  def parse_xml xml
    doc = Hpricot.XML xml
    flows = (doc/'TextFlow')

    stack = []
    xml = ['<Document>']
    flows.each do |flow|
      handle_flow(flow, stack, xml) unless is_instructions?(flow)
    end
    xml << '</Document>'
    xml.join('')
  end

  def handle_flow flow, stack, xml
    flow.traverse_element do |element|
      case element.name
        when 'ETag'
          stack << clean(element)
          xml << '<'
          xml << stack.last
          xml << '>'
        when 'String'
          string = clean(element)
          xml << string
        when 'ElementEnd'
          name = stack.pop
          xml << '</'
          xml << name
          xml << '>'
          xml << "\n" unless name[/(Day|STHouse|STLords|STText)/]
      end
    end
  end
end