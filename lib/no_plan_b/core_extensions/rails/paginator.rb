# We extend the paginator so that we can pass it an array for the items_per_page value
# We adjust the number of items retrieved and the offset based upon these values, with the assumption
# that the final value is repeated 

# This only works with the version 1.x rails paginator
if Rails::VERSION::STRING.match(/^1/)
module ActionController
  module Pagination
    class Paginator

      # logger.my_debug "Loading the paginator extensions"

      # Since I'm adding the items_per_page as an array, I need to change the initialization method
      def initialize(controller, item_count, items_per_page, current_page=1)
        raise ArgumentError, 'must have at least one item per page' if
        [*items_per_page].max <= 0

        @controller = controller
        @item_count = item_count || 0
        @items_per_page = items_per_page
        @pages = {}

        self.current_page = current_page
      end

      def page_count
        unless @page_count
          if ( @items_per_page.kind_of?(Array) )
            pages = 0
            total = 0
            @items_per_page.each do |items_per_page|
              total += items_per_page
              pages += 1
              break if ( @item_count <= total)
            end
            @item_count < total ? pages : pages + (q,r=(@item_count-total).divmod(@items_per_page.last); r==0? q : q+1)
          else
            (q,r=@item_count.divmod(@items_per_page); r==0? q : q+1)
          end
        end
      end


      class Page

        # Returns the item offset for the first item in this page.
        # Note that @number is indexed from 1, that is, @number 1 is the first page
        def offset
          return 0 if @number <= 1
          if @paginator.items_per_page.kind_of?(Array) 
            @number <= @paginator.items_per_page.size ? @paginator.items_per_page[0...@number-1].sum :  @paginator.items_per_page.sum + (@number-@paginator.items_per_page.size-1)*@paginator.items_per_page.last
          else
            @paginator.items_per_page * (@number - 1)
          end
        end

        # Returns the number of the last item displayed.
        def last_item
          if @paginator.items_per_page.kind_of?(Array) 
            [offset + (@number <= @paginator.items_per_page.size ? @paginator.items_per_page[@number-1] : @paginator.items_per_page.last),@paginator.item_count].min
          else
            [@paginator.items_per_page * @number, @paginator.item_count].min
          end
        end

        # Number of items to show on this page
        def items
          if ( @paginator.items_per_page.kind_of?(Array) )
            @number <= @paginator.items_per_page.size ? @paginator.items_per_page[@number-1] : @paginator.items_per_page.last
          else
            @paginator.items_per_page
          end
        end

        # Returns the limit/offset array for this page.
        def to_sql
          if ( @paginator.items_per_page.kind_of?(Array))
            [items, offset]
          else
            [@paginator.items_per_page, offset]
          end
        end

      end

    end

  end
end
end
