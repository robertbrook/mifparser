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

  describe 'when parsing MIF file' do

    it 'should call out to mif2xml' do
      mif_file = 'pbc0930106a.mif'
      tempfile_path = '/var/folders/iZ/iZnGaCLQEnyh56cGeoHraU+++TI/-Tmp-/pbc0930106a.mif.xml.334.0'

      temp_xml_file = mock(Tempfile, :path => tempfile_path)
      Tempfile.should_receive(:new).with("#{mif_file}.xml", '.').and_return temp_xml_file
      temp_xml_file.should_receive(:close)
      Kernel.should_receive(:system).with("mif2xml < #{mif_file} > #{tempfile_path}")

      @parser.should_receive(:parse_xml_file).with(tempfile_path)
      temp_xml_file.should_receive(:delete)

      @parser.parse(mif_file)
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