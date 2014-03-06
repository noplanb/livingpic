# ========================
# = ThumbWidthCalculator =
# ========================

class window.ThumbWidthCalculator
  
  @INSTANCE: null
  
  constructor: (@window_width=$(window).innerWidth(), @max_img_width=200, @min_img_width=150, @margin=5, @border=1, @min_cols=2) ->
    ThumbWidthCalculator.INSTANCE = @
    @window_width = @window_width
    # @img_padding = 2 * (@margin + @border)
    @img_padding = 2 * (@margin)
    @img_inner_width = 0
    @max_img_outer_width = @max_img_width + @img_padding
    
  img_outer_width: (img_inner_width) =>
    img_inner_width + @img_padding
    
  thumb_width: =>
    if (@window_width / @min_cols) < @max_img_outer_width
      @img_inner_width = (@window_width / @min_cols) - @img_padding - 3
    else
      @img_inner_width = @shrink_to_fit()
    return @img_inner_width
      
  shrink_to_fit: =>
    try_img_width = @max_img_width
    best_left_over = @max_img_width
    best_fit_img_width = @max_img_width
    while try_img_width >= @min_img_width
      left_over = @window_width % @img_outer_width(try_img_width)
      if left_over < best_left_over
        best_left_over = left_over 
        best_fit_img_width = try_img_width
      try_img_width--
    return best_fit_img_width    