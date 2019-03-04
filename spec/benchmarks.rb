require_relative 'spec_helper'
require 'sinatra/base'
require 'json'
require 'benchmark/ips'
require 'benchmark/memory'

Conditionals = lambda do |params = {}|
  @artists = DB[:artists]
  if (genre = params[:genre])
    @artists = @artists.grep(:genre, "%#{genre}%", case_insensitive: true)
  end
  if (name = params[:name])
    @artists = @artists.grep(:name, "%#{name}%", case_insensitive: true)
  end

  @artists.to_json
end

Reduction = lambda do |params = {}|
  @artists = Rack::Reducer.call(params, dataset: DB[:artists], filters: [
    ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
    ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
  ])
  @artists.to_json
end

Beta = Rack::Reducer.new(
  DB[:artists],
  ->(genre:) { grep(:genre, "%#{genre}%", case_insensitive: true) },
  ->(name:) { grep(:name, "%#{name}%", case_insensitive: true) },
)

%i[ips memory].each do |profile|
  puts "Running benchmark/#{profile}..."

  Benchmark.send(profile) do |bm|
    bm.report('raw conditionals') do
      Conditionals.call({ name: 'blake', genre: 'electric' })
    end

    bm.report('reducer (1.0)') do
      Reduction.call({ name: 'blake', genre: 'electric' })
    end

    bm.report('reducer (2.0 beta)') do
      Beta.call({ name: 'blake', genre: 'electric' }).to_json
    end

    bm.compare!
  end
end
