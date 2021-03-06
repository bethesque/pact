require 'spec_helper'

module Pact
  describe Reification do

    let(:response_spec) do
      {
        woot: /x/,
        britney: 'britney',
        nested: { foo: /bar/, baz: 'qux' },
        my_term: Term.new(generate: 'wiffle', matcher: /^wif/),
        array: ['first', /second/]
      }
    end

    describe "from term" do

      subject { Reification.from_term(response_spec) }

      it "converts regexes into real data" do
        expect(subject[:woot]).to eql 'x'
      end

      it "converts terms into real data" do
        expect(subject[:my_term]).to eql 'wiffle'
      end

      it "passes strings through" do
        expect(subject[:britney]).to eql 'britney'
      end

      it "handles nested hashes" do
        expect(subject[:nested]).to eql({ foo: 'bar', baz: 'qux' })
      end

      it "handles arrays" do
        expect(subject[:array]).to eql ['first', 'second']
      end

    end

  end
end
