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
  def parse mif_file, options={}
    xml_file = Tempfile.new("#{mif_file}.xml",'.')
    xml_file.close # was open
    Kernel.system "mif2xml < #{mif_file} > #{xml_file.path}"
    result = parse_xml_file(xml_file.path, options)
    xml_file.delete
    result
  end

  # e.g. parser.parse_xml_file("pbc0930106a.mif.xml")
  def parse_xml_file xml_file, options
    parse_xml(IO.read(xml_file), options)
  end

  def is_instructions?(flow)
    instruction_regexp = /(`Header'|REISSUE|Running H\/F|line of text which is to be numbered|Use the following fragment to insert an amendment line number)/
    flow.inner_text[instruction_regexp] ||
    (flow.at('PgfTag') && flow.at('PgfTag/text()').to_s[/AmendmentLineNumber/])
  end

  def parse_xml xml, options={}
    doc = Hpricot.XML xml
    flows = (doc/'TextFlow')

    stack = []
    xml = [options[:html] ? '<html><body>' : '<Document>']
    flows.each do |flow|
      unless is_instructions?(flow)
        if options[:html]
          handle_flow_to_html(flow, stack, xml)
        else
          handle_flow(flow, stack, xml)
        end
      end
    end
    xml << [options[:html] ? '</body></html>' : '</Document>']
    xml.join('')
  end

  DIV = %w[Amendments-Commons Head HeadConsider Date Committee Clause-Committee].inject({}) {|hash, value| hash[value] = true; hash}
  P = %w[Stageheader CommitteeShorttitle ClausesToBeConsidered MarshalledOrderNote Sponsors Amendment-Text SubSection].inject({}) {|hash, value| hash[value] = true; hash}
  SPAN = %w[Day Date-text STText Notehead NoteTxt Sponsor Amendment-Number Number Page Line ].inject({}) {|hash, value| hash[value] = true; hash}

  def handle_flow_to_html(flow, stack, xml)
    flow.traverse_element do |element|
      case element.name
        when 'ETag'
          tag = clean(element)
          stack << tag
          if DIV[tag]
            xml << "<div class='#{tag}'>"
          elsif P[tag]
            xml << "<p class='#{tag}'>"
          elsif SPAN[tag]
            xml << "<span class='#{tag}'>"
          else
            xml << '<p>'
            xml << tag
            xml << ': '
          end
        when 'String'
          string = clean(element)
          xml << string
        when 'ElementEnd'
          tag = stack.pop
          if DIV[tag]
            xml << "</div>"
          elsif P[tag]
            xml << "</p>"
          elsif SPAN[tag]
            xml << "</span>"
          else
            xml << '</p>'
          end
          # xml << name
          # xml << '>'
          xml << "\n" unless tag[/(Day|STHouse|STLords|STText)/]
      end
    end
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