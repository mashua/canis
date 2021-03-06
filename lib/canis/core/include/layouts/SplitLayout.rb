# ----------------------------------------------------------------------------- #
#         File: SplitLayout.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2014-05-10 - 13:48
#      License: MIT
#  Last update: 2014-05-10 20:19
# ----------------------------------------------------------------------------- #
#  SplitLayout.rb  Copyright (C) 2012-2014 j kepler
#  ---- 
#  This layout allows for complex arrangements of stacks and flows. One can divide the layout
#  into splits (vertical or horizontal) and keep dividing a split, or placing a component in it.
#  However, to keep it simple and reduce the testing, I am insisting that a weightage be specified
#  with a split.
#
#       layout = SplitLayout.new :height => -1, :top_margin => 1, :bottom_margin => 1, :left_margin => 1
#       x, y = layout.vsplit( 0.30, 0.70)
#       x.component = mylist
#       y1, y2 = y.split( 0.40, 0.60 )
#       y2.component = mytable
#       y11,y12,y13 = y1.vsplit( 0.3, 0.3, 0.4)
#       y11 = list1
#       y12 = list2
#       y13 = list3
#
#       Or hopefully:
#
#       layout.split(0.3, 0.7) do |x,y|
#         x.component = mylist
#         y.split(0.4, 0.6) do |a,b|
#           b.component = mytable
#           a.vsplit( 0.3, 0.3, 0.4) do | p,q,r |
#             p.component = list1
#           end
#         end
#      end
#
#  
class Split

  attr_reader :component
  attr_accessor :name
  attr_reader :splits
  attr_accessor :height, :width, :top, :left
  # link to parent
  # own weight
  attr_accessor :parent, :weight
  # weights of child splits, given in cons
  attr_accessor :split_wts
  attr_reader :type

  def initialize type, weight, parent
    @type = type
    @weight = weight
    @parent = parent
  end
  def _split type, args, &block
    @split_wts = args
    @splits = []
    args.each do |e|
      @splits << Split.new(type, e, self)
    end
    if block_given?
      yield @splits.flatten
    else
      return @splits.flatten
    end
  end
  def split *args, &block
    _split :h, args, &block
  end
  def vsplit *args, &block
    _split :v, args, &block
  end

  # Set a component into a split.
  # set name of component as name of split, more for debugging
  def component=(c)
    @component = c
    @name = c.name || c.class.to_s
  end

  # shorthand to place a component in a split.
  alias :<< :component=
end


  
require 'canis/core/include/layouts/abstractlayout'
class SplitLayout < AbstractLayout

  # @param [Form]  optional give a form      
  # @param [Hash]  optional give settings/attributes which will be set into variables
  def initialize arg, config={}, &block
    super
    @splits = nil
  end
  def _split type, args, &block
    @splits = []
    @split_wts = args
    args.each do |e|
      @splits << Split.new(type, e, self)
    end
    if block_given?
      yield @splits.flatten
    else
      return @splits.flatten
    end
  end

  def split *args, &block
    raise "already split " if @splits
    _split :h, args, &block
  end
  def vsplit *args, &block
    raise "already split " if @splits
    $log.debug "  SPLIT GOT #{args} "
    _split :v, args, &block
  end
  alias :top :top_margin
  alias :left :left_margin


  # This program lays out the widgets deciding their row and columm and height and weight.
  # This program is called once at start of application, and again whenever a RESIZE event happens.
  def do_layout
    _init_layout
    recalc @splits, @top_margin, @left_margin if @splits
    #
    $log.debug "  layout finished "
  end
  def recalc splits, r, c
    splits.each_with_index do |s,i|
      $log.debug "  recalc #{i}, #{s} "
      p = s.parent
      s.top = r
      s.left = c
      case s.type
      when :v
        s.width = (s.weight * p.width ).floor
        s.height = p.height
        c += s.width
      when :h
        s.height = (s.weight * p.height ).floor
        s.width = p.width
        r += s.height
      end
      if s.component
        s.component.height = s.height
        s.component.row = s.top
        s.component.col = s.left
        s.component.width = s.width
      elsif s.splits
        recalc s.splits, s.top, s.left if s.splits
      else
        raise "Neither splits nor a component placed in #{s} #{s.type}, #{s.weight} #{s.name}"
      end
    end

  end
end
