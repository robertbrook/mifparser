require 'rubygems'
gem 'rspec'
require 'spec'

require File.dirname(__FILE__) + '/../lib/mif_parser'

def fixture(filename)
  open("#{File.dirname(__FILE__)}/fixtures/#{filename}").read
end

require 'test/unit'
require 'activesupport'
require '/Library/Ruby/Gems/1.8/gems/rspec-rails-1.2.7.1/lib/spec/rails/matchers/assert_select.rb'
require '/Library/Ruby/Gems/1.8/gems/actionpack-2.3.2/lib/action_controller/vendor/html-scanner.rb'
require '/Library/Ruby/Gems/1.8/gems/actionpack-2.3.2/lib/action_controller/assertions/selector_assertions.rb'

include ActionController::Assertions::SelectorAssertions
include Test::Unit::Assertions

module ActionController
  module Assertions
    module SelectorAssertions

      def _check_exception_class(args)
        args.partition do |klass|
          next if klass.instance_of?(Module)
          assert((Exception >= klass), "Should expect a class of exception, #{klass}")
          true
        end
      end

      def _expected_exception?(actual_exception, exceptions, modules)
        (exceptions.include?(actual_exception.class) or modules.any? { |mod| actual_exception.is_a?(mod) })
      end

      def _wrap_assertion
        @_assertion_wrapped ||= false
        if @_assertion_wrapped then
          return yield
        else
          @_assertion_wrapped = true
          begin
            (add_assertion
            return yield)
            ensure
              @_assertion_wrapped = false
          end
        end
      end

      def add_assertion
        # do nothing
      end

      def assert(boolean, message = nil)
        _wrap_assertion do
          assert_block("assert should not be called with a block.") do
            (not block_given?)
          end
          assert_block(build_message(message, "<?> is not true.", boolean)) { boolean }
        end
      end

      def assert_block(message = "assert_block failed.")
        _wrap_assertion do
          raise(Test::Unit::Assertions::AssertionFailedError.new(message.to_s)) unless yield
        end
      end

      def assert_equal(expected, actual, message = nil)
        full_message = build_message(message, "<?> expected but was\n<?>.\n", expected, actual)
        assert_block(full_message) { (expected == actual) }
      end

      def assert_in_delta(expected_float, actual_float, delta, message = "")
        _wrap_assertion do
          { expected_float => "first float", actual_float => "second float", delta => "delta" }.each do |float, name|
            assert_respond_to(float, :to_f, "The arguments must respond to to_f; the #{name} did not")
          end
          assert_operator(delta, :>=, 0.0, "The delta should not be negative")
          full_message = build_message(message, "<?> and\n<?> expected to be within\n<?> of each other.\n", expected_float, actual_float, delta)
          assert_block(full_message) do
            ((expected_float.to_f - actual_float.to_f).abs <= delta.to_f)
          end
        end
      end

      def assert_instance_of(klass, object, message = "")
        _wrap_assertion do
          assert_equal(Class, klass.class, "assert_instance_of takes a Class as its first argument")
          full_message = build_message(message, "<?> expected to be an instance of\n<?> but was\n<?>.\n", object, klass, object.class)
          assert_block(full_message) { object.instance_of?(klass) }
        end
      end

      def assert_kind_of(klass, object, message = "")
        _wrap_assertion do
          assert(klass.kind_of?(Module), "The first parameter to assert_kind_of should be a kind_of Module.")
          full_message = build_message(message, "<?>\nexpected to be kind_of\\?\n<?> but was\n<?>.", object, klass, object.class)
          assert_block(full_message) { object.kind_of?(klass) }
        end
      end

      def assert_match(pattern, string, message = "")
        _wrap_assertion do
          pattern = case pattern
          when String then
            Regexp.new(Regexp.escape(pattern))
          else
            pattern
          end
          full_message = build_message(message, "<?> expected to be =~\n<?>.", string, pattern)
          assert_block(full_message) { string.=~(pattern) }
        end
      end

      def assert_nil(object, message = "")
        assert_equal(nil, object, message)
      end

      def assert_no_match(regexp, string, message = "")
        _wrap_assertion do
          assert_instance_of(Regexp, regexp, "The first argument to assert_no_match should be a Regexp.")
          full_message = build_message(message, "<?> expected to not match\n<?>.", regexp, string)
          assert_block(full_message) { (not regexp.=~(string)) }
        end
      end

      def assert_not_equal(expected, actual, message = "")
        full_message = build_message(message, "<?> expected to be != to\n<?>.", expected, actual)
        assert_block(full_message) { (not (expected == actual)) }
      end

      def assert_not_nil(object, message = "")
        full_message = build_message(message, "<?> expected to not be nil.", object)
        assert_block(full_message) { (not object.nil?) }
      end

      def assert_not_same(expected, actual, message = "")
        full_message = build_message(message, "<?>\nwith id <?> expected to not be equal\\? to\n<?>\nwith id <?>.\n", expected, expected.__id__, actual, actual.__id__)
        assert_block(full_message) { (not actual.equal?(expected)) }
      end

      def assert_nothing_raised(*args)
        _wrap_assertion do
          Module.===(args.last) ? (message = "") : (message = args.pop)
          exceptions, modules = _check_exception_class(args)
          begin
            yield
          rescue Exception => e
            if ((args.empty? and (not e.instance_of?(Test::Unit::Assertions::AssertionFailedError))) or _expected_exception?(e, exceptions, modules)) then
              assert_block(build_message(message, "Exception raised:\n?", e)) { false }
            else
              raise
            end
          end
          # do nothing
        end
      end

      def assert_nothing_thrown(message = "", &proc)
        _wrap_assertion do
          assert(block_given?, "Should have passed a block to assert_nothing_thrown")
          begin
            proc.call
          rescue NameError, ThreadError => error
            raise(error) unless UncaughtThrow[error.class].=~(error.message)
            full_message = build_message(message, "<?> was thrown when nothing was expected", $1.intern)
            flunk(full_message)
          end
          assert(true, "Expected nothing to be thrown")
        end
      end

      def assert_operator(object1, operator, object2, message = "")
        _wrap_assertion do
          full_message = build_message(nil, "<?>\ngiven as the operator for #assert_operator must be a Symbol or #respond_to\\?(:to_str).", operator)
          assert_block(full_message) do
            (operator.kind_of?(Symbol) or operator.respond_to?(:to_str))
          end
          full_message = build_message(message, "<?> expected to be\n?\n<?>.\n", object1, AssertionMessage.literal(operator), object2)
          assert_block(full_message) { object1.__send__(operator, object2) }
        end
      end

      def assert_raise(*args)
        _wrap_assertion do
          Module.===(args.last) ? (message = "") : (message = args.pop)
          exceptions, modules = _check_exception_class(args)
          expected = (args.size == 1) ? (args.first) : (args)
          actual_exception = nil
          full_message = build_message(message, "<?> exception expected but none was thrown.", expected)
          assert_block(full_message) do
            begin
              yield
            rescue Exception => actual_exception
              break
            end
            false
          end
          full_message = build_message(message, "<?> exception expected but was\n?", expected, actual_exception)
          assert_block(full_message) do
            _expected_exception?(actual_exception, exceptions, modules)
          end
          actual_exception
        end
      end

      def assert_raises(*args, &block)
        assert_raise(*args, &block)
      end

      def assert_respond_to(object, method, message = "")
        _wrap_assertion do
          full_message = build_message(nil, "<?>\ngiven as the method name argument to #assert_respond_to must be a Symbol or #respond_to\\?(:to_str).", method)
          assert_block(full_message) do
            (method.kind_of?(Symbol) or method.respond_to?(:to_str))
          end
          full_message = build_message(message, "<?>\nof type <?>\nexpected to respond_to\\?<?>.\n", object, object.class, method)
          assert_block(full_message) { object.respond_to?(method) }
        end
      end

      def assert_same(expected, actual, message = "")
        full_message = build_message(message, "<?>\nwith id <?> expected to be equal\\? to\n<?>\nwith id <?>.\n", expected, expected.__id__, actual, actual.__id__)
        assert_block(full_message) { actual.equal?(expected) }
      end

      def assert_send(send_array, message = "")
        _wrap_assertion do
          assert_instance_of(Array, send_array, "assert_send requires an array of send information")
          assert((send_array.size >= 2), "assert_send requires at least a receiver and a message name")
          full_message = build_message(message, "<?> expected to respond to\n<?(?)> with a true value.\n", send_array[0], AssertionMessage.literal(send_array[1].to_s), send_array[(2..-1)])
          assert_block(full_message) do
            send_array[0].__send__(send_array[1], *send_array[(2..-1)])
          end
        end
      end

      def assert_throws(expected_symbol, message = "", &proc)
        _wrap_assertion do
          assert_instance_of(Symbol, expected_symbol, "assert_throws expects the symbol that should be thrown for its first argument")
          assert_block("Should have passed a block to assert_throws.") { block_given? }
          caught = true
          begin
            (catch(expected_symbol) do
              proc.call
              caught = false
            end
            full_message = build_message(message, "<?> should have been thrown.", expected_symbol)
            assert_block(full_message) { caught })
          rescue NameError, ThreadError => error
            raise(error) unless UncaughtThrow[error.class].=~(error.message)
            full_message = build_message(message, "<?> expected to be thrown but\n<?> was thrown.", expected_symbol, $1.intern)
            flunk(full_message)
          end
        end
      end

      def build_message(head, template = nil, *arguments)
        template &&= template.chomp
        return Test::Unit::Assertions::AssertionMessage.new(head, template, arguments)
      end

      def flunk(message = "Flunked")
        assert_block(build_message(message)) { false }
      end

      def self.use_pp=(value)
        AssertionMessage.use_pp = value
      end
    end
  end
end

module Spec::Rails::Matchers
  class AssertSelect
    private
    module TestResponseOrString
      def test_response?
        false
      end
    end
  end
end

def have_tag(*args, &block)
  Spec::Rails::Matchers::AssertSelect.new(:assert_select, self, *args, &block)
end

def prepare_args(args, current_scope = nil)
  return args if current_scope.nil?
  defaults = current_scope.options || {:strict => false, :xml => false}
  args << {} unless args.last.is_a?(::Hash)
  args.last[:strict] = defaults[:strict] if args.last[:strict].nil?
  args.last[:xml] = defaults[:xml] if args.last[:xml].nil?
  args
end

def with_tag(*args, &block)
  args = prepare_args(args, @__current_scope_for_assert_select)
  @__current_scope_for_assert_select.should have_tag(*args, &block)
end
