require 'light_store'
require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
Bundler.require(:default, :test)

require 'rspec'
require 'redis'
require 'logger'
describe LightStore::Data do
  before(:each) do
    LightStore.configure do |config|
      config.redis = Redis.new
      config.pipelined = false
    end
  end
  context 'for class methods' do
    let(:dataset1) {
        [
          {id: 2, s_id: 20, name_1: 'John', name_2: 'Krakis', super_date: Time.new(2002)},
          {id: 2, s_id: 25, name_1: 'Jake', name_2: 'Harken', super_date: Time.new(2003)},
          {id: 3, s_id: 30, name_1: 'Jake', name_2: 'Marken', super_date: Time.new(2004)},
          {id: 3, s_id: 35, name_1: 'Jake', name_2: 'Barken', super_date: Time.new(2005)},
          {id: 3, s_id: 40, name_1: 'Jake', name_2: 'Farken', super_date: Time.new(2006)},
          {id: 3, s_id: 45, name_1: 'Jake', name_2: 'Larken', super_date: Time.new(2007)},
          {id: 3, s_id: 50, name_1: 'Jake', name_2: 'Tarken', super_date: Time.new(2008)},
        ]
      }
    before(:each) do
      class SomeReport < LightStore::Data
        primary_field :id
        date_constraint_field :super_date
      end
      SomeReport.add_data(dataset1)
    end
    after(:each) do
      SomeReport.clear_all
    end
    # make these tests testier
    describe '#add_data' do
      it 'sets data' do
        SomeReport.add_data(dataset1)
      end
      it 'gets data no args' do
        SomeReport.get_data()
      end
      it 'gets data with primary key' do
        SomeReport.get_data(primary_key: 2)
      end
      it 'gets data with date range' do
        SomeReport.get_data(date_range: [2000, '2013'])
      end
      it 'gets data with primary key and date range' do
        SomeReport.get_data(primary_key: 1, date_range: [Time.new(2001), Time.new(2013)])
      end
    end
  end
end