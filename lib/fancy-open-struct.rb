require 'ostruct'
require 'forwardable'
require 'awesome_print'
require 'fancy-open-struct/version'

class FancyOpenStruct < OpenStruct

  extend Forwardable

  hash_methods = Hash.instance_methods(false) - (Hash.instance_methods(false) & OpenStruct.instance_methods(false)) - [:[], :[]=]
  def_instance_delegators :@table, *hash_methods

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

  def recurse_over_array(array)
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

  alias_method :to_hash, :to_h

  def debug_inspect(options = {})
    # Refer to the "Awesome Print" gem documentation for information about which options are available
    # The awesome_print gem can be found at https://rubygems.org/gems/awesome_print
    ap(@table, options)
  end

  alias_method :display_recursive_open_hash, :debug_inspect

  # Hash getter method which translates the key to a Symbol
  def [](key)
    @table[key.to_sym]
  end

  # Hash setter method which translates the key to a Symbol and also creates
  # a getter method (OpenStruct member) for accessing the key/value later via dot syntax
  def []=(key, value)
    modifiable[new_ostruct_member(key.to_sym)] = value
  end

  private

  # Dynamically handle any attempts to get or set values via dot syntax
  # if the OpenStruct member methods haven't already been created
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