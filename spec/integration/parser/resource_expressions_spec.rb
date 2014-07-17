require 'spec_helper'
require 'puppet_spec/compiler'
require 'matchers/resource'

describe "(PUP-511) Puppet resource expressions" do
  include PuppetSpec::Compiler
  include Matchers::Resource

  shared_examples_for "resource expressions" do |cases|
    def find_resource_in(manifest, expression_under_test) 
      catalog = compile_to_catalog(manifest)

      title = expression_under_test.gsub(/\[|\]/,'')
      expect(catalog).to have_resource("Notify[#{title}]")
    end

    cases.each do |parameters|
      expression, test, type_or_exception = *parameters
      case test
      when "resource"
        it "accepts a title with the literal #{type_or_exception} #{expression} in it" do
          find_resource_in(<<-MANIFEST, expression)
            notify { #{expression}: }
          MANIFEST
        end

        it "accepts a title with the #{type_or_exception} #{expression} passed in through a variable" do
          find_resource_in(<<-MANIFEST, expression)
            $x = #{expression}
            notify { $x: }
          MANIFEST
        end
      else
        it "raises an error for a literal title expression #{expression}" do
          expect do
            catalog = compile_to_catalog(<<-MANIFEST)
              notify { #{expression}: }
            MANIFEST
          end.to raise_error(Puppet::Error, type_or_exception)
        end

        it "raises an error for a title expression #{expression} passed in through a variable" do
          expect do
            catalog = compile_to_catalog(<<-MANIFEST)
              $x = #{expression}
              notify { $x: }
            MANIFEST
          end.to raise_error(Puppet::Error, type_or_exception)
        end
      end 
    end
  end

  describe "future parser" do
    before :each do
      Puppet[:parser] = 'future'
    end

    it_behaves_like("resource expressions", [
      ["thing"              ,"resource", "String"],
      ["1"                  ,"resource", "Integer"],
      ["3.0"                ,"resource", "Float"],
      ["true"               ,"resource", "Boolean"],
      ["false"              ,"resource", "Boolean"],
      ["[thing]"            ,"resource", "Array[String]"],
      ["[1]"                ,"resource", "Array[Integer]"],
      ["[3.0]"              ,"resource", "Array[Float]"],
      ["[true]"             ,"resource", "Array[Boolean]"],
      ["[false]"            ,"resource", "Array[Boolean]"],
      ["undef"              ,"error", /Evaluation Error.*No title provided/],
      ["{nested => hash}"   ,"error", /Can not use a Hash where a String is expected/],
      ["/regexp/"           ,"error", /can't convert Regexp to String/],
      ["default"            ,"error", /Can not use a Symbol\(:default\) where a String is expected/],
      ["[undef]"            ,"error", /Evaluation Error.*No title provided/],
      ["[[nested, array]]"  ,"error", /Nested arrays are unexpectedly allowed/],
      ["[{nested => hash}]" ,"error", /Can not use a Hash where a String is expected/],
      ["[/regexp/]"         ,"error", /can't convert Regexp to String/],
      ["[default]"          ,"error", /Can not use a Symbol\(:default\) where a String is expected/],
    ])
  end

  describe "current parser" do
    it_behaves_like("resource expressions", [
      ["thing"              ,"resource", "String"],
      ["1"                  ,"resource", "Integer"],
      ["3.0"                ,"resource", "Float"],
      ["true"               ,"resource", "Boolean"],
      ["false"              ,"resource", "Boolean"],
      ["[thing]"            ,"resource", "Array[String]"],
      ["[1]"                ,"resource", "Array[Integer]"],
      ["[3.0]"              ,"resource", "Array[Float]"],
      ["[true]"             ,"resource", "Array[Boolean]"],
      ["[false]"            ,"resource", "Array[Boolean]"],
      ["undef"              ,"error", /Evaluation Error.*No title provided/],
      ["{nested => hash}"   ,"error", /Can not use a Hash where a String is expected/],
      ["/regexp/"           ,"error", /can't convert Regexp to String/],
      ["default"            ,"error", /Can not use a Symbol\(:default\) where a String is expected/],
      ["[undef]"            ,"error", /succeeds -- deprecate\?/],
      ["[[nested, array]]"  ,"error", /Nested arrays are unexpectedly allowed/],
      ["[{nested => hash}]" ,"error", /succeeds -- deprecate\?/],
      ["[/regexp/]"         ,"error", /Syntax error at ':'; expected '}'/],
      ["[default]"          ,"error", /Syntax error at ':'; expected '}'/],
    ])
  end
end
