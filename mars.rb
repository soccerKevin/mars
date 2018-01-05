require 'pry' # debugging tool
require 'pp' # pretty print

class PathFinder
  attr_reader :map

  # mars = map
  def initialize(mars, start_x, start_y)
    @map = grid_to_map mars
    @start_point = @map[start_y][start_x]
    @path_keys = []
  end

  def points_of_interest
    @POIs ||= @map.map do |row|
      row.select{ |point| point.interesting? }
    end.flatten
  end

  def grid_to_map(grid)
    @map = grid.each_with_index.map do |row, y|
      row.each_with_index.map{ |type, x| Point.new type, x, y }
    end
  end

  def find_paths
    path_trees = points_of_interest.map do |interesting_point|
      tree_first_node = traverse @start_point, interesting_point
    end

    path_tree = traverse @start_point, points_of_interest.first
    paths = path_tree.path_to points_of_interest.first.i
    paths = paths.extract_values
    binding.pry
  end

  # poi = point of interest
  # returns a node
  def traverse(current_point, poi, current_path_key=[])
    # has this point been visited
    pp('visited') and return nil if current_path_key.include? current_point.i

    # add this point to the path
    new_path = current_path_key + [current_point.i]
    node = Node.new new_path

    pp('not traversable') and return node if !current_point.traversable?

    # if current_point is the interesting one
    # mark it's node as interesting for shortest path checking
    if current_point.i == poi.i
      pp 'winner'
      return node
    end

    pp 'checking a new node'

    possible_points = [
      { y: current_point.y + 1, x: current_point.x },
      { y: current_point.y - 1, x: current_point.x },
      { y: current_point.y,     x: current_point.x + 1 },
      { y: current_point.y,     x: current_point.x - 1 }
    ]

    children = possible_points.map do |coords|
      return nil unless @map[coords[:y]] # nil if row doesn't exist (y is out of bounds)
      point = @map[coords[:y]][coords[:x]]
    end.compact # compact to remove nils

    # check the next nodes
    children.each{ |child| node.add_child traverse child, poi, new_path }
    node # ruby returns result of last line by default

  rescue Exception => e
    binding.pry
  end
end

$points_index = 0

class Point
  attr_accessor :x, :y, :i

  def initialize(type, x, y)
    # name each point for path tracking
    @i = ($points_index = $points_index + 1)
    @type = type
    @x = x
    @y = y
  end

  def traversable?
    @type != 'X'
  end

  def interesting?
    @type == '!'
  end
end

class Node
  attr_accessor :value, :path_key

  def initialize(path_key=[])
    @children = []
    @path_key = path_key
  end

  def add_child(child)
    @children.push child unless child.nil?
  end

  def path_to(point_index)
    return @path_key if @path_key.include? point_index
    return @children.map{ |child| child.path_to point_index }
  end
end

# for random chars
class Randomizer
  CHARS = ('a'..'z').to_a + ('0'..'9').to_a + ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')']

  def self.char
    CHARS.sample
  end
end

class Array
  def flatten_blanks
    each{ |elem| elem.flatten_blanks if elem.is_a?(Array) }
    reject!{ |elem| elem.is_a?(Array) && elem.length < 1 }
    flatten! if self.length < 2
    self
  end

  def extract_values
    @values = []
    find_values
    @values
  end

  def find_values
    each do |elem|
      if elem.first.is_a? Integer
        @values.push elem
      elsif elem.first.is_a? Array
        @values.concat elem.extract_values
      end
    end
  end
end

mars = [
  "+++++++++",
  "+XXX!+XXX",
  "++!+++X!+",
  "++++!+X++",
  "++XX+++++",
  "++!X++!++"
].map{ |s| s.split '' }

path_finder = PathFinder.new mars, 7, 0
path_finder.find_paths

