class Module 
  # Ruby Treasures 0.4
  # Copyright (C) 2002 Paul Brannan <paul@atdesk.com>
  # 
  # You may distribute this software under the same terms as Ruby (see the file
  # COPYING that was distributed with this library).
  # 
  ##
  # alias_method, except for class methods
  #
  # @return the return value of alias_method
  #
  def alias_class_method(new, orig)
    retval = nil
    eval %{
      class << self
        retval =
          ##
          # @ignore
          alias_method :#{new}, :#{orig}
      end
    }
    retval
  end
  
  # Delegates to #alias_method_chain to provide aliasing for class methods. 
  def alias_class_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?
    alias_class_method "#{aliased_target}_without_#{feature}#{punctuation}", target
    alias_class_method target, "#{aliased_target}_with_#{feature}#{punctuation}"
  end
  
end
