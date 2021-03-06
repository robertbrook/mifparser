require 'tempfile'
require 'rubygems'
require 'hpricot'
require 'htmlentities'

class MifParser

  VERSION = "0.0.0"

  def clean element
    element.at('text()').to_s[/`(.+)'/]
    text = $1
    if text
      text.gsub!('\xd4 ', '‘')
      text.gsub!('\xd5 ','’')
      text.gsub!('\xd2 ','“')
      text.gsub!('\xd3 ','”')
    else
      ''
    end
    text
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
    xml = [options[:html] ? '<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body>' : '<Document>']
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

  def get_char element
    char = element.at('text()').to_s
    case char
      when 'EmSpace'
        ' '
      when 'Pound'
        '£'
      when 'EmDash'
        '—'
      when 'HardReturn'
        "\n"
      else
        '[[' + char + ']]'
    end
  end

  def get_html_for_char element
    char = get_char(element)
    if char == "\n"
      "<br />"
    else
      HTMLEntities.new.encode(char)
    end
  end

  def handle_flow flow, stack, xml
    flow.traverse_element do |element|
      case element.name
        when 'ETag'
          tag = clean(element)
          stack << tag
          xml << '<'
          xml << tag
          xml << '>'
        when 'Char'
          xml << get_char(element)
        when 'PgfNumString', 'String'
          string = clean(element)
          xml << string
        when 'ElementEnd'
          tag = stack.pop
          xml << '</'
          xml << tag
          xml << '>'
          xml << "\n" unless tag[/(Day|STHouse|STLords|STText)/]
      end
    end
  end

  DIV = %w[Amendments.Commons Head HeadConsider Date
      Committee Clause.Committee Order.Committee
      CrossHeadingSch Amendment
      NewClause.Committee Order.House].inject({}){|h,v| h[v]=true; h}

  P = %w[Stageheader CommitteeShorttitle ClausesToBeConsidered
      MarshalledOrderNote SubSection Schedule.Committee
      Para Para.sch SubPara.sch SubSubPara.sch
      Definition
      CrossHeadingTitle Heading.text
      ClauseTitle ClauseText Move TextContinuation
      OrderDate OrderPreamble OrderText OrderPara
      Order.Motion OrderHeading
      OrderAmendmentText
      ResolutionPreamble].inject({}){|h,v| h[v]=true; h}

  SPAN = %w[Day Date.text STText Notehead NoteTxt
      Amendment.Text Amendment.Number Number Page Line ].inject({}){|h,v| h[v]=true; h}

  UL = %w[Sponsors].inject({}){|h,v| h[v]=true; h}
  LI = %w[Sponsor].inject({}){|h,v| h[v]=true; h}

  HR = %w[Separator.thick].inject({}){|h,v| h[v]=true; h}

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
          elsif UL[tag]
            xml << "<ul class='#{tag}'>"
          elsif LI[tag]
            xml << "<li class='#{tag}'>"
          elsif SPAN[tag]
            xml << "<span class='#{tag}'>"
          elsif HR[tag]
            xml << "<!-- page break -->"
          else
            xml << '<p>[['
            xml << tag
            xml << ']]: '
          end
        when 'Char'
          xml << get_html_for_char(element)
        when 'PgfNumString', 'String'
          string = clean(element)
          if string
            string.gsub!('\t',' ')
            string = HTMLEntities.new.encode(string)
            xml << string
          end
        when 'ElementEnd'
          tag = stack.pop
          if DIV[tag]
            xml << "</div>"
          elsif P[tag]
            xml << "</p>"
          elsif UL[tag]
            xml << "</ul>"
          elsif LI[tag]
            xml << "</li>"
          elsif SPAN[tag]
            xml << "</span>"
          elsif HR[tag]
            # xml << ""
          else
            xml << '</p>'
          end
          # xml << name
          # xml << '>'
          xml << "\n" unless tag[/(Day|STHouse|STLords|STText)/]
      end
    end
  end

end