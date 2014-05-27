require 'ostruct'
require 'forwardable'

class FancyOpenStruct < OpenStruct
  VERSION = "0.1.3"

  extend Forwardable

  hash_methods = Hash.instance_methods(false) - (Hash.instance_methods(false) & OpenStruct.instance_methods(false))
  def_delegators :@table, *hash_methods

  def initialize(hash=nil, args={})
    @recurse_over_arrays = args.fetch(:recurse_over_arrays, false)
    @table = {}
    if hash
      for k, v in hash
        @table[k.to_sym] = v
        new_ostruct_member(k)
      end
    end
    @sub_elements = {}
  end

  def to_h
    @table.dup.update(@sub_elements) do |k, oldval, newval|
      if newval.kind_of?(self.class)
        newval.to_h
      elsif newval.kind_of?(Array)
        newval.map { |a| a.kind_of?(self.class) ? a.to_h : a }
      else
        raise "Cached value of unsupported type: #{newval.inspect}"
      end
    end
  end

  def new_ostruct_member(name)
    name = name.to_sym
    unless self.respond_to?(name)
      define_singleton_method name do
        v = @table[name]
        if v.is_a?(Hash)
          @sub_elements[name] ||= self.class.new(v, :recurse_over_arrays => @recurse_over_arrays)
        elsif v.is_a?(Array) and @recurse_over_arrays
          @sub_elements[name] ||= recurse_over_array v
        else
          v
        end
      end
      define_singleton_method("#{name}=") { |x| modifiable[name] = x }
      define_singleton_method("#{name}_as_a_hash") { @table[name] }
    end
    name
  end

  def recurse_over_array array
    array.map do |a|
      if a.is_a? Hash
        self.class.new(a, :recurse_over_arrays => true)
      elsif a.is_a? Array
        recurse_over_array a
      else
        a
      end
    end
  end

  def debug_inspect(io = STDOUT, indent_level = 0, recursion_limit = 12)
    display_recursive_open_hash(io, @table, indent_level, recursion_limit)
  end

  def display_recursive_open_hash(io, ostrct_or_hash, indent_level, recursion_limit)

    if recursion_limit <= 0
      # protection against recursive structure (like in the tests)
      io.puts '  '*indent_level + '(recursion limit reached)'
    else
      #puts ostrct_or_hash.inspect
      if ostrct_or_hash.is_a?(self.class)
        ostrct_or_hash = ostrct_or_hash.marshal_dump
      end

      # We'll display the key values like this :    key =  value
      # to align display, we look for the maximum key length of the data that will be displayed
      # (everything except hashes)
      data_indent = ostrct_or_hash \
        .reject { |k, v| v.is_a?(self.class) || v.is_a?(Hash) } \
        .max { |a, b| a[0].to_s.length <=> b[0].to_s.length }[0].to_s.length
      # puts "max length = #{data_indent}"

      ostrct_or_hash.each do |key, value|
        if value.is_a?(self.class) || value.is_a?(Hash)
          io.puts '  '*indent_level + key.to_s + '.'
          display_recursive_open_hash(io, value, indent_level + 1, recursion_limit - 1)
        else
          io.puts '  '*indent_level + key.to_s + ' '*(data_indent - key.to_s.length) + ' = ' + value.inspect
        end
      end
    end

    true
  end

  def []=(*args)
    len = args.length
    raise ArgumentError, "wrong number of arguments (#{len} for 2)", caller(1) if len != 2
    modifiable[new_ostruct_member(args[0].to_sym)] = args[1]
  end

  def method_missing(mid, *args) # :nodoc:
    mname = mid.id2name
    len = args.length
    if mname.chomp!('=')
      raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1) if len != 1
      # Set up an instance method to point to the key/value in the table and set the value
      modifiable[new_ostruct_member(mname.to_sym)] = args[0]
    elsif @table.has_key?(mid)
      # The table has apparently been modified externally, so we need to set up
      # an instance method to point to the key/value in the table.
      new_ostruct_member(mname.to_sym)
      self.send(mid)
    else
      nil
    end
  end
end