require 'spec_helper'
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
      blank_obj = Object.new
      h = {:asdf => 'John Smith', :foo => [{:bar => blank_obj}, {:baz => nil}]}
      fos = FancyOpenStruct.new(h)
      fos.to_h.should == h
      fos.to_hash.should == h
    end

    describe 'hash methods' do

      let(:fos) { FancyOpenStruct.new }

      it 'forwards all of the basic Hash methods directly to the @table instance variable' do
        Hash.instance_methods(false).each do |method_name|
          fos.respond_to?(method_name).should be_true
        end
      end

      it 'recovers gracefully even when the internal hash @table is directly modified via hash methods' do
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

      describe 'The Hash table getter method, []' do
        it 'only accepts one argument' do
          expect { fos[:key1, :key2] }.to raise_error(ArgumentError, /2 for 1/)
        end

        it "handles hash methods for setting values" do
          fos['blah'] = "John Smith"
          fos[:foo] = "George Washington"
          fos.blah.should == "John Smith"
          fos.foo.should == "George Washington"
        end

        it 'converts string hash keys to symbols' do
          fos['blah'] = "John Smith"
          fos['blah'].should == "John Smith"
          fos[:blah].should == "John Smith"
          fos.blah.should == "John Smith"
          fos.to_h['blah'].should == nil
        end
      end

      describe 'The Hash table setter method, []=' do
        it 'only accepts two arguments' do
          expect { fos[:key1, :key2] = :value }.to raise_error(ArgumentError, /3 for 2/)
        end
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

      it 'lets you access keys via strings or symbols' do
        h = {'blah' => 'John Smith'}
        fos = FancyOpenStruct.new(h)
        fos.to_h.should == {:blah => "John Smith"}
        fos['blah'].should == "John Smith"
        fos['foo'] = 'bar'
        fos.foo.should == 'bar'
        fos[:foo].should == 'bar'
        fos['foo'].should == 'bar'
        fos.to_h.should == {:blah => "John Smith", :foo => 'bar'}
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
        it "Retains changes across Array look-ups" do
          subject.blah[1].foo = "Dr Scott"
          subject.blah[1].foo.should == "Dr Scott"
        end
        it "propagates the changes through to .to_h across Array look-ups" do
          subject.blah[1].foo = "Dr Scott"
          subject.to_h.should == {
              :blah => [{:foo => '1'}, {:foo => "Dr Scott"}, 'baz']
          }
        end

        context "when array is nested deeper" do
          let(:deep_hash) { {:foo => {:blah => blah_list}} }
          subject { FancyOpenStruct.new(deep_hash, :recurse_over_arrays => true) }

          it { subject.foo.blah.length.should == 3 }
          it "Retains changes across Array look-ups" do
            subject.foo.blah[1].foo = "Dr Scott"
            subject.foo.blah[1].foo.should == "Dr Scott"
          end

          it 'recurses and updates both shallow and deep values if they are changed' do
            fos = FancyOpenStruct.new({}, :recurse_over_arrays => true)
            deep_array_hash = [
                {
                    :foo =>
                        {:bar => :baz}
                },
                {
                    :qux => [
                        {:zap => :zam}, {:zip => :boop}
                    ]
                }
            ]
            fos.bar = deep_array_hash
            fos.bar[0].foo.bar.should == :baz
            fos.bar[1].qux[0].zap.should == :zam
            fos.bar[1].qux[0].zap = :changed1
            fos.bar[1].qux[0].zap.should == :changed1
            fos.bar[1].qux[1].zip.should == :boop
            fos.bar[1].qux[1].zip = :changed2
            fos.bar[1].qux[1].zip.should == :changed2
            fos.bar = {:qux_new => [{:zap => :zam}, {:zip => :boop}]}
            fos.bar.qux.should be_nil
            fos.bar.qux_new[0].zap.should == :zam
            fos.bar.qux_new[1].zip.should == :boop
          end
        end

        context "when array is in an array" do
          let(:haah) { {:blah => [blah_list]} }
          subject { FancyOpenStruct.new(haah, :recurse_over_arrays => true) }

          it { subject.blah.length.should == 1 }
          it { subject.blah[0].length.should == 3 }
          it "Retains changes across Array look-ups" do
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

    it "should have a simple way of display complex FancyOpenStruct data" do
      h = {
          :blah => {
              :blargh => 'Brad'
          },
          'example_string' => {
              :foo => :bar,
              :baz => {'qux' => :zam}
          }
      }
      fos = FancyOpenStruct.new(h)

      expected_result = "{" + \
                        "\n           :blah => {" + \
                        "\n  :blargh => \"Brad\"" + \
                        "\n }," + \
                        "\n :example_string => {" + \
                        "\n  :foo => :bar," + \
                        "\n  :baz => {" + \
                        "\n   \"qux\" => :zam" + \
                        "\n  }" + \
                        "\n }" + \
                        "\n}" + \
                        "\n"

      debug_inspect = capture_stdout do
        fos.debug_inspect(:indent => 1, :plain => true)
      end
      debug_inspect.string.should == expected_result
    end

    it "creates nested objects via subclass" do
      FancyOpenStructSubClass = Class.new(FancyOpenStruct)

      fossc = FancyOpenStructSubClass.new({:one => [{:two => :three}]}, recurse_over_arrays: true)

      fossc.one.first.class.should == FancyOpenStructSubClass
    end

    it 'returns nil for missing keys' do
      fos = FancyOpenStruct.new {}
      fos.foo.should be_nil
      fos['bar'].should be_nil
      fos[:baz].should be_nil
    end

    describe 'method aliases' do
      it 'responds to #to_hash' do
        FancyOpenStruct.new.respond_to?(:to_hash).should be_true
      end
    end
  end # additionnel features

end # describe FancyOpenStruct
