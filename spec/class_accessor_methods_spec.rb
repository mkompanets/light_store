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
  context 'for class accessor methods' do
    before(:each) do
      class TestReport < LightStore::Data
        primary_field :some_field_name
        date_constraint_field :some_date_field
      end
      class DefaultTestReport < LightStore::Data
      end
    end
    context 'for base_name' do
      it 'sets base_name' do
        TestReport.base_name.should == 'LightStore:TestReport'
      end
    end
    context 'for primary_field' do
      it 'returns primary_field' do
        TestReport.primary_field.should_not be_nil
      end
      it 'errors without primary_field' do
        expect{DefaultTestReport.primary_field}
          .to raise_error(ArgumentError, 'primary_field must be set')
      end
    end
    context 'for date_constraint_field' do
      it 'returns date_constraint_field' do
        TestReport.date_constraint_field.should_not be_nil
      end
      it 'errors without date_constraint_field' do
        expect{DefaultTestReport.date_constraint_field}
          .to raise_error(ArgumentError, 'date_constraint_field must be set')
      end
    end
    context 'for row' do
      let(:date) { '2012-05-15' }
      let(:key) { 1 }
      let(:h) {{some_field_name: 1, some_date_field: date}}
      before(:each) do
        TestReport.row = h
      end
      it 'sets and gets row' do
        TestReport.row.should == h
      end
      it 'gets primary_key' do
        TestReport.primary_key.should == key
      end
      it 'gets secondary_key' do
        TestReport.secondary_key.should == Time.parse(date).to_i
      end
      it 'has row_key' do
        TestReport.row_key.should match(":row:#{TestReport.primary_key}:#{TestReport.secondary_key}")
      end
      it 'has row_reference_key' do
        TestReport.row_reference_key.should match(":key:#{TestReport.primary_key}:#{TestReport.secondary_key}")
      end
      it 'has primary_range_key' do
        TestReport.primary_range_key(TestReport.primary_key).should match(":primary_range:#{TestReport.primary_key}")
      end
      it 'has range_key' do
        TestReport.range_key.should match(":range")
      end
    end
  end
end