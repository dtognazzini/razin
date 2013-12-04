require 'nesty'

module Razin
  extend self
  
  def raises(*expected_errors)
    yield
  rescue *([Razin::ProgrammingError] + expected_errors)
    raise
  rescue
    raise Razin::UnexpectedError
  end
end

require "razin/version"
require "razin/exceptions"
