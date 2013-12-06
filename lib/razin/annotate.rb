module Razin
  module Annotate
    def self.extended(target_class)
      target_class.class_eval do
        class << self
          def razin_raises
            @razin_raises
          end
          
          attr_writer :razin_raises
          
          if RUBY_VERSION >= "2.0.0"
            def razin_module
              @razin_module ||= Module.new
            end
          end
        end
      end
    end
    
    class MethodWrapperPre20
      def self.wrap(target_class, method_name, expected)
        protected_method_name = "razin_wrapped_#{method_name}"

        target_class.class_eval do
          alias_method protected_method_name, method_name
        end
        target_class.class_eval <<-RUBY
          def #{method_name}(*args, &block)
            Razin.raises(*#{expected.inspect}) do
              #{protected_method_name}(*args, &block)
            end
          end
        RUBY
      end
    end

    class MethodWrapper20
      def self.wrap(target_class, method_name, expected)
        target_class.send(:prepend, target_class.razin_module)
        target_class.razin_module.class_eval <<-RUBY
          def #{method_name}(*args, &block)
            Razin.raises(*#{expected.inspect}) do
              super
            end
          end
        RUBY
      end
    end

    def method_added(method_name)
      super
      wrap_method(self, method_name)
    end
    
    def singleton_method_added(method_name)
      super
      
      meta_class = class << self; self; end
      wrap_method(meta_class, method_name)
    end

    def raises(*expected)
      self.razin_raises = expected
    end
    
    def wrap_method(context, method_name)
      if method_name.to_s.start_with?("razin") || context.razin_raises.nil?
        return 
      end
      
      razin_raises = context.razin_raises
      context.razin_raises = nil
      
      wrapper = RUBY_VERSION < "2.0.0" ? MethodWrapperPre20 : MethodWrapper20
      wrapper.wrap(context, method_name, razin_raises)
    end
  end
end
