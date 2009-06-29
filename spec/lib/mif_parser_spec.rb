require File.dirname(__FILE__) + '/../spec_helper.rb'

describe MifParser do

  before do
    @parser = MifParser.new
  end
  
  describe 'when creating new parser' do
    it 'should create parser' do
      @parser.should_not be_nil
    end
  end

  describe 'when parsing MIF XML file' do
    before do
      @result = @parser.parse_xml(fixture('pbc0930106a.mif.xml'))
    end

    it 'should make ETags into elements' do
      puts @result
      @result.should have_tag('Amendments-Commons') do
        with_tag('Head') do
          with_tag('HeadNotice') do
            with_tag('NoticeOfAmds', :text => 'Notices of Amendments')
            with_tag('Given', :text => 'given on')
            with_tag('Date') do
              with_tag('Day', :text => 'Monday')
              with_tag('Date-text', :text => '1 June 2009')
            end
            with_tag('Stageheader', :text => 'Public Bill Committee' )
            with_tag('CommitteeShorttitle') do
              with_tag('STText', :text => 'Local Democracy, Economic Development and Construction Bill')
              with_tag('STHouse', :text => '[Lords]')
            end
          end
        end
      end
    end
  end

end