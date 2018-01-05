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
    solutions = points_of_interest.map do |interesting_point|
      path_tree = traverse @start_point, interesting_point
      paths = path_tree.path_to(interesting_point.i).extract_values
      { poi: interesting_point, paths: paths }
    end

    best_solutions = solutions.map do |solution|
      { poi: solution[:poi], solution: solution[:paths].shortest }
    end

    pp best_solutions
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
      next unless coords[:y] > -1 && coords[:x] > -1 # prevents wrapping around the map
      next if @map[coords[:y]].nil? # nil if row doesn't exist (y is out of bounds)
      point = @map[coords[:y]][coords[:x]]
    end.compact # compact to remove nils

    # check the next nodes
    children.each{ |child| node.add_child traverse child, poi, new_path }
    node # ruby returns result of last line by default

  rescue Exception => e
    binding.pry
  end
end

class Point
  attr_accessor :x, :y, :i

  def initialize(type, x, y)
    @i = "#{x}#{y}".to_i
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

# monkey patching on array to simplify the results
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

  def shortest
    min_length = 1000
    value = nil
    each do |elem|
      if elem.length < min_length
        min_length = elem.length
        value = elem
      end
    end
    value
  end
end

mars = [
  "+++++++++",
  "+XXX!+XX+",
  "++!+++X!+",
  "++++!+X++",
  "++XX+++++",
  "++!X++!++"
].map{ |s| s.split '' }

path_finder = PathFinder.new mars, 7, 0
path_finder.find_paths

