# Modification to the association collection so that it's possible to run the 'uniq' method on it
# with a block given, enabling us to run uniq on a particular attribute of the association object, for example
# Example
#   comment.users.uniq { |u| u.last_name = 'Smith' }
module UniqueWithBlock
  def uniq_with_block(collection=self)
    if block_given?
      seen = Set.new
      collection.inject([]) do |kept, record|
        v = yield record
        unless seen.include?(v)
          kept << record
          seen << v
        end
        kept
      end
    else
      uniq_without_block(collection)
    end
  end
end

module ActiveRecord
  module Associations
    
    # Rails 2
    if Rails.version.slice(0,1) == '2'
      class AssociationCollection < AssociationProxy #:nodoc:
        include UniqueWithBlock
        alias_method_chain :uniq, :block
      end
    else
      # Rails 3
      class CollectionAssociatino < CollectionProxy
        include UniqueWithBlock
        alias_method_chain :uniq, :block
      end
    end
  end
end
