require 'rubygems'; require 'spec'; require 'lib/mifparser'

begin
  require 'echoe'

  Echoe.new("mifparser", MifParser::VERSION) do |m|
    m.description = File.readlines("README").first
    # m.rubyforge_name = "mifparser"
    m.rdoc_options << '--inline-source'
    m.rdoc_pattern = ["README"]
    m.dependencies = ["hpricot >=0.6"]
    m.executable_pattern = 'bin/mifparse'
  end

rescue LoadError
  puts "You need to install the echoe gem to perform meta operations on this gem"
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/mif_parser.rb"
end

desc "Run all examples with RCov"
task :rcov do
  sh '/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby -Ilib -S rcov --text-report  -o "coverage" -x "Library" spec/lib/**/*'
end