require 'test_helper'

module Razin
  class AnnotateTest < Test::Unit::TestCase
    class Error1 < StandardError; end
    class Error2 < StandardError; end
    
    class TestClass1
      extend Razin::Annotate
      
      raises Error1
      def mortar(error_to_raise, *args)
        raise error_to_raise, *args
      end
      
      class << self
        extend Razin::Annotate

        raises Error1
        def mortar(error_to_raise, *args)
          raise error_to_raise, *args
        end
      end
    end
        
    def test_instance_method_raises__allowed
      raised = assert_raise Error1 do
        TestClass1.new.mortar(Error1, "message 1")
      end
      
      assert_equal "message 1", raised.message
    end
    
    def test_instance_method_raises__unexpected
      raised = assert_raise Razin::UnexpectedError do
        TestClass1.new.mortar(ArgumentError, "argument is incorrect")
      end
      
      assert_equal ArgumentError, raised.nested.class
      assert_equal "argument is incorrect", raised.nested.message
    end
    
    def test_instance_method_raises__programming_error
      raised = assert_raise Razin::ProgrammingError do
        TestClass1.new.mortar(Razin::ProgrammingError, "oops, I did it again")
      end
      
      assert_equal nil, raised.nested
      assert_equal "oops, I did it again", raised.message
    end
    
    def test_class_method_raises__allowed
      raised = assert_raise Error1 do
        TestClass1.mortar(Error1, "message 1")
      end
      
      assert_equal "message 1", raised.message
    end
    
    def test_class_method_raises__unexpected
      raised = assert_raise Razin::UnexpectedError do
        TestClass1.mortar(ArgumentError, "argument is incorrect")
      end
      
      assert_equal ArgumentError, raised.nested.class
      assert_equal "argument is incorrect", raised.nested.message
    end
    
    def test_class_method_raises__programming_error
      raised = assert_raise Razin::ProgrammingError do
        TestClass1.mortar(Razin::ProgrammingError, "oops, I did it again")
      end
      
      assert_equal nil, raised.nested
      assert_equal "oops, I did it again", raised.message
    end
  end
end