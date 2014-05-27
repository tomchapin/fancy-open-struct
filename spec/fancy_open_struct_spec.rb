require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fancy-open-struct'

describe FancyOpenStruct do

  describe "behavior it inherits from OpenStruct" do

    it "can represent arbitrary data objects" do
      fos = FancyOpenStruct.new
      fos.blah = "John Smith"
      fos.blah.should == "John Smith"
    end

    it "can be created from a hash" do
      h = {:asdf => 'John Smith'}
      fos = FancyOpenStruct.new(h)
      fos.asdf.should == "John Smith"
    end

    it "can modify an existing key" do
      h = {:blah => 'John Smith'}
      fos = FancyOpenStruct.new(h)
      fos.blah = "George Washington"
      fos.blah.should == "George Washington"
    end

    describe "handling of arbitrary attributes" do
      subject { FancyOpenStruct.new }
      before(:each) do
        subject.blah = "John Smith"
      end

      describe "#respond?" do
        it { subject.should respond_to :blah }
        it { subject.should respond_to :blah= }
        it { subject.should_not respond_to :asdf }
        it { subject.should_not respond_to :asdf= }
      end # describe #respond?

      describe "#methods" do
        it { subject.methods.map(&:to_sym).should include :blah }
        it { subject.methods.map(&:to_sym).should include :blah= }
        it { subject.methods.map(&:to_sym).should_not include :asdf }
        it { subject.methods.map(&:to_sym).should_not include :asdf= }
      end # describe #methods
    end # describe handling of arbitrary attributes
  end # describe behavior it inherits from OpenStruct

  describe "improvements on OpenStruct" do
    it "can be converted back to a hash" do
      h = {:asdf => 'John Smith'}
      fos = FancyOpenStruct.new(h)
      fos.to_h.should == h
    end

    describe 'hash methods' do
      it "handles hash methods for setting values" do
        fos = FancyOpenStruct.new
        fos['blah'] = "John Smith"
        fos[:foo] = "George Washington"
        fos.blah.should == "John Smith"
        fos.foo.should == "George Washington"
      end

      it 'converts string hash keys to symbols' do
        fos = FancyOpenStruct.new
        fos['blah'] = "John Smith"
        fos['blah'].should == "John Smith"
        fos[:blah].should == "John Smith"
        fos.blah.should == "John Smith"
        fos.to_h['blah'].should == nil
      end

      it 'forwards all of the basic Hash methods directly to the @table instance variable' do
        fos = FancyOpenStruct.new
        Hash.instance_methods(false).each do |method_name|
          fos.respond_to?(method_name).should be_true
        end
      end

      it 'recovers gracefully even when the internal hash @table is directly modified via hash methods' do
        fos = FancyOpenStruct.new
        fos.foo = 'bar'
        fos.to_h.should == {:foo => "bar"}
        other_hash = {:baz => :qux}
        fos.merge! other_hash
        fos.to_h.should == {:foo => "bar", :baz => :qux}
        fos.foo.should == 'bar'
        fos.baz.should == :qux
        fos.instance_variable_set :@table, {}
        fos.foo.should == nil
        fos.baz.should == nil
      end
    end

    context 'using strings instead of symbols as hash keys' do
      it "can be created from a hash" do
        h = {'asdf' => 'John Smith'}
        fos = FancyOpenStruct.new(h)
        fos.asdf.should == "John Smith"
      end

      it "can modify an existing key" do
        h = {'blah' => 'John Smith'}
        fos = FancyOpenStruct.new(h)
        fos.blah = "George Washington"
        fos.blah.should == "George Washington"
      end

      it 'saves string hash keys as symbols' do
        h = {'blah' => 'John Smith'}
        fos = FancyOpenStruct.new(h)
        fos.to_h.should == {:blah => "John Smith"}
        fos[:blah].should == "John Smith"
      end
    end
  end

  describe "recursive behavior" do
    let(:h) { {:blah => {:another => 'value'}} }
    subject { FancyOpenStruct.new(h) }

    it "returns accessed hashes as FancyOpenStructs instead of hashes" do
      subject.blah.another.should == 'value'
    end

    it "uses #key_as_a_hash to return key as a Hash" do
      subject.blah_as_a_hash.should == {:another => 'value'}
    end

    describe "handling loops in the origin Hashes" do
      let(:h1) { {:a => 'a'} }
      let(:h2) { {:a => 'b', :h1 => h1} }
      before(:each) { h1[:h2] = h2 }

      subject { FancyOpenStruct.new(h2) }

      it { subject.h1.a.should == 'a' }
      it { subject.h1.h2.a.should == 'b' }
      it { subject.h1.h2.h1.a.should == 'a' }
      it { subject.h1.h2.h1.h2.a.should == 'b' }
      it { subject.h1.should == subject.h1.h2.h1 }
      it { subject.h1.should_not == subject.h1.h2 }
    end # describe handling loops in the origin Hashes

    it "can modify a key of a sub-element" do
      h = {
          :blah => {
              :blargh => 'Brad'
          }
      }
      fos = FancyOpenStruct.new(h)
      fos.blah.blargh = "Janet"
      fos.blah.blargh.should == "Janet"
    end

    context "after a sub-element has been modified" do
      let(:hash) do
        {
            :blah => {
                :blargh => 'Brad'
            }
        }
      end
      subject { FancyOpenStruct.new(hash) }
      before(:each) { subject.blah.blargh = "Janet" }
      it "returns a hash that contains those modifications" do
        subject.to_h.should == {:blah => {:blargh => "Janet"}}
      end
    end


    describe 'recursing over arrays' do
      let(:blah_list) { [{:foo => '1'}, {:foo => '2'}, 'baz'] }
      let(:h) { {:blah => blah_list} }

      context "when recursing over arrays is enabled" do
        subject { FancyOpenStruct.new(h, :recurse_over_arrays => true) }

        it { subject.blah.length.should == 3 }
        it { subject.blah[0].foo.should == '1' }
        it { subject.blah[1].foo.should == '2' }
        it { subject.blah_as_a_hash.should == blah_list }
        it { subject.blah[2].should == 'baz' }
        it "Retains changes acfoss Array lookups" do
          subject.blah[1].foo = "Dr Scott"
          subject.blah[1].foo.should == "Dr Scott"
        end
        it "propagates the changes through to .to_h acfoss Array lookups" do
          subject.blah[1].foo = "Dr Scott"
          subject.to_h.should == {
              :blah => [{:foo => '1'}, {:foo => "Dr Scott"}, 'baz']
          }
        end

        context "when array is nested deeper" do
          let(:deep_hash) { {:foo => {:blah => blah_list}} }
          subject { FancyOpenStruct.new(deep_hash, :recurse_over_arrays => true) }

          it { subject.foo.blah.length.should == 3 }
          it "Retains changes acfoss Array lookups" do
            subject.foo.blah[1].foo = "Dr Scott"
            subject.foo.blah[1].foo.should == "Dr Scott"
          end

        end

        context "when array is in an array" do
          let(:haah) { {:blah => [blah_list]} }
          subject { FancyOpenStruct.new(haah, :recurse_over_arrays => true) }

          it { subject.blah.length.should == 1 }
          it { subject.blah[0].length.should == 3 }
          it "Retains changes acfoss Array lookups" do
            subject.blah[0][1].foo = "Dr Scott"
            subject.blah[0][1].foo.should == "Dr Scott"
          end

        end

      end # when recursing over arrays is enabled

      context "when recursing over arrays is disabled" do
        subject { FancyOpenStruct.new(h) }

        it { subject.blah.length.should == 3 }
        it { subject.blah[0].should == {:foo => '1'} }
        it { subject.blah[0][:foo].should == '1' }
      end # when recursing over arrays is disabled

    end # recursing over arrays
  end # recursive behavior

  describe "additional features" do

    before(:each) do
      h1 = {:a => 'a'}
      h2 = {:a => 'b', :h1 => h1}
      h1[:h2] = h2
      @fos = FancyOpenStruct.new(h2)
    end

    it "should have a simple way of display" do
      @output = <<-QUOTE
a = "b"
h1.
  a = "a"
  h2.
    a = "b"
    h1.
      a = "a"
      h2.
        a = "b"
        h1.
          a = "a"
          h2.
            a = "b"
            h1.
              a = "a"
              h2.
                a = "b"
                h1.
                  a = "a"
                  h2.
                    a = "b"
                    h1.
                      a = "a"
                      h2.
                        (recursion limit reached)
      QUOTE
      @io = StringIO.new
      @fos.debug_inspect(@io)
      @io.string.should match /^a = "b"$/
      @io.string.should match /^h1\.$/
      @io.string.should match /^  a = "a"$/
      @io.string.should match /^  h2\.$/
      @io.string.should match /^    a = "b"$/
      @io.string.should match /^    h1\.$/
      @io.string.should match /^      a = "a"$/
      @io.string.should match /^      h2\.$/
      @io.string.should match /^        a = "b"$/
      @io.string.should match /^        h1\.$/
      @io.string.should match /^          a = "a"$/
      @io.string.should match /^          h2\.$/
      @io.string.should match /^            a = "b"$/
      @io.string.should match /^            h1\.$/
      @io.string.should match /^              a = "a"$/
      @io.string.should match /^              h2\.$/
      @io.string.should match /^                a = "b"$/
      @io.string.should match /^                h1\.$/
      @io.string.should match /^                  a = "a"$/
      @io.string.should match /^                  h2\.$/
      @io.string.should match /^                    a = "b"$/
      @io.string.should match /^                    h1\.$/
      @io.string.should match /^                      a = "a"$/
      @io.string.should match /^                      h2\.$/
      @io.string.should match /^                        \(recursion limit reached\)$/
    end

    it "creates nested objects via subclass" do
      FancyOpenStructSubClass = Class.new(FancyOpenStruct)

      fossc = FancyOpenStructSubClass.new({:one => [{:two => :three}]}, recurse_over_arrays: true)

      fossc.one.first.class.should == FancyOpenStructSubClass
    end
  end # additionnel features

end # describe FancyOpenStruct
