require_relative 'refinements'
require_relative 'parser'

module Rack
  module Reducer
    # call `reduce` on a params hash, filtering data via lambdas with
    # matching keyword arguments
    class Reduction
      using Refinements # define Proc#required_argument_names, #satisfies?, etc

      def initialize(dataset:, filters:)
        @dataset = dataset
        @filters = filters
      end

      def call(params)
        parsed = Parser.call(params)
        @filters.reduce(@dataset) do |data, filter|
          next data unless filter.satisfies?(parsed)

          data.instance_exec(parsed.slice(*filter.all_argument_names), &filter)
        end
      end
    end

    private_constant :Reduction
  end
end
