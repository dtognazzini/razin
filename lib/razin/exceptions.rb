module Razin
  class ProgrammingError < Nesty::NestedStandardError
  end
  
  class UnexpectedError < ProgrammingError
  end
end
