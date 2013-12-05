require 'test_helper'

module Razin
  class RaisesTest < Test::Unit::TestCase
    class Error1 < StandardError; end
    class Error2 < StandardError; end
    class Error3 < StandardError; end

    def raises_mortar(error_to_raise, *args)
      Razin.raises(Error1, Error2, Error3) do
        raise error_to_raise, *args
      end
    end

    def test_raises__allowed
      raised = assert_raise Error1 do
        raises_mortar(Error1, "message 1")
      end
      
      assert_equal "message 1", raised.message
    end
    
    def test_raises__unexpected
      raised = assert_raise Razin::UnexpectedError do
        raises_mortar(ArgumentError, "argument is incorrect")
      end
      
      assert_equal ArgumentError, raised.nested.class
      assert_equal "argument is incorrect", raised.nested.message
    end
    
    def test_raises__programming_error
      raised = assert_raise Razin::ProgrammingError do
        raises_mortar(Razin::ProgrammingError, "oops, I did it again")
      end
      
      assert_equal nil, raised.nested
      assert_equal "oops, I did it again", raised.message
    end
  end
end