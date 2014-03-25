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
    end
  end
  context 'for class initialization' do
    before(:each) do
      class DefaultValuesClass < LightStore::Data
      end
      class SetValuesClass < LightStore::Data
        set_namespace 'some_namespace'
        set_prefix 'some_prefix'
        set_primary_key 'some_id'
        set_secondary_key 'some_secondary_key'
        set_sortable_field :f1
        set_sortable_field :f2, :integer
        set_sortable_field :f3, :float
        set_sortable_field :f4, :datetime
      end
      SetValuesClass.clear_all
    end
    describe 'DefaultValuesClass' do
      let(:default_values_instance) { DefaultValuesClass.new }
      it 'datastore type is Redis' do
        DefaultValuesClass.datastore.class.name.should == 'Redis'
      end
      it 'sets class level namespace to light_store' do
        DefaultValuesClass.namespace.should == 'light_store'
      end
      it 'sets class level prefix to class name' do
        DefaultValuesClass.prefix.should == 'DefaultValuesClass'
      end
      it 'sets instance level namespace to light_store' do
        default_values_instance.namespace.should == 'light_store'
      end
      it 'sets class level primary_key to :id by default' do
        DefaultValuesClass.primary_key.should == :id
      end
      it 'sets instance level primary_key to :id by default' do
        default_values_instance.primary_key.should == :id
      end
      it 'raises ArgumentError if secondary_key not set' do
        expect{DefaultValuesClass.secondary_key}.to raise_error(ArgumentError)
      end
    end
    describe 'SetValuesClass' do
      let(:set_values_instance) { SetValuesClass.new }
      let(:sample_h1) {
        {
          'some_id' => 1,
          'some_secondary_key' => 's2',
          f1: '1',
          f2: '2',
          f3: '3.2',
          f4: Time.now,
        }
      }
      context 'for class methods' do
        it 'sets class namespace to some_namespace' do
          SetValuesClass.namespace.should == 'some_namespace'
        end
        it 'sets class level prefix to some_prefix' do
        SetValuesClass.prefix.should == 'some_prefix'
      end
        it 'sets class primary_key to some_id' do
          SetValuesClass.primary_key.should == 'some_id'
        end
        it 'sets class secondary_key to some_secondary_key' do
          SetValuesClass.secondary_key.should == 'some_secondary_key'
        end
      end
      context 'for key setting methods' do
        describe '#base_key' do
          it 'sets key to #{namespace}:#{prefix}' do
            k = "#{SetValuesClass.namespace}:#{SetValuesClass.prefix}"
            SetValuesClass.base_key.should == k
          end
        end
        describe '#base_member_ids_key' do
          it 'sets key to #{base_key}:member_ids' do
            k = "#{SetValuesClass.base_key}:member_ids"
            SetValuesClass.base_member_ids_key.should == k
          end
        end
        describe '#base_sorted_member_ids_key' do
          it 'sets key to "#{base_key}:sorted_member_ids"' do
            k = "#{SetValuesClass.base_key}:sorted_member_ids"
            SetValuesClass.base_sorted_member_ids_key.should == k
          end
        end
        describe '#base_data_key' do
          it 'sets key to #{namespace}:#{prefix}:data' do
            k = "#{SetValuesClass.namespace}:#{SetValuesClass.prefix}:data"
            SetValuesClass.base_data_key.should == k
          end
        end
        describe '#get_primary_id' do
          it 'gets primary key' do
            k = sample_h1['some_id']
            SetValuesClass.get_primary_id(sample_h1).should == k
          end
          it 'raises ArgumentError if not set' do
            expect{SetValuesClass.get_primary_id({})}.to raise_error(ArgumentError)
          end
        end
        describe '#get_secondary_id' do
          it 'gets secondary_key key' do
            k = sample_h1['some_secondary_key']
            SetValuesClass.get_secondary_id(sample_h1).should == k
          end
          it 'raises ArgumentError if not set' do
            expect{SetValuesClass.get_secondary_id({})}.to raise_error(ArgumentError)
          end
        end
        describe '#sortable_fields' do
          it 'field_type defaults to integer' do
            SetValuesClass.sortable_fields.should include({field_name: :f1, field_type: :integer})
          end
        end
        describe '#get_data_row_key' do
          it 'gets data row key' do
            d = SetValuesClass.get_data_row_key(sample_h1)
            base_key = SetValuesClass.base_data_key
            primary_id = SetValuesClass.get_primary_id(sample_h1)
            secondary_id = SetValuesClass.get_secondary_id(sample_h1)
            d.should == "#{base_key}:#{primary_id}:#{secondary_id}"
          end
        end
        describe '#get_member_id_key' do
          it 'gets member id key' do
            d = SetValuesClass.get_member_id_key(sample_h1)
            base_key = SetValuesClass.base_member_ids_key
            primary_id = SetValuesClass.get_primary_id(sample_h1)
            d.should == "#{base_key}:#{primary_id}"
          end
        end
        describe '#get_sorted_member_id_key' do
          it 'gets sorted member id key' do
            field_name = SetValuesClass.sortable_fields.first[:field_name]
            primary_id = SetValuesClass.get_primary_id(sample_h1)
            d = SetValuesClass.get_sorted_member_id_key(sample_h1, field_name)
          end
        end
        describe '#get_score' do
          it 'gets the score for integer type' do
            v = 1
            SetValuesClass.get_score(v, :integer).should be_a Integer
          end
          it 'gets the score for float type' do
            v = 1
            SetValuesClass.get_score(v, :float).should be_a Float
          end
          it 'gets the score for datetime type' do
            v = Time.now.to_s
            SetValuesClass.get_score(v, :datetime).should be_a Integer
          end
          it 'raises an error for nil value' do
            v = nil
            expect{SetValuesClass.get_score(v, :unknown)}.to raise_error(ArgumentError)
          end
          it 'raises an error for unexpected type' do
            v = Time.now.to_s
            expect{SetValuesClass.get_score(v, :unknown)}.to raise_error(ArgumentError)
          end
        end
        describe '#add_member_id' do
          it 'adds member id to set' do
            SetValuesClass.add_member_id(sample_h1).should be_true
            row_id = SetValuesClass.get_data_row_key(sample_h1)
            SetValuesClass.get_member_ids.should include(row_id)
          end
        end
        describe '#add_sorted_member_ids' do
          it 'adds sorted member ids to set' do
            SetValuesClass.add_sorted_member_ids(sample_h1)
          end
        end
        describe '#add_sorted_member_id' do
          it 'adds sorted member id to set' do
            field_name = SetValuesClass.sortable_fields.first[:field_name]
            field_type = SetValuesClass.sortable_fields.first[:field_type]
            SetValuesClass.add_sorted_member_id(sample_h1, field_name, field_type)
          end
        end
      end
      context 'for instance methods' do
        it 'sets instance namespace to some_namespace' do
          set_values_instance.namespace.should == 'some_namespace'
        end
        it 'sets instance primary_key to some_id' do
          set_values_instance.primary_key.should == 'some_id'
        end
        it 'sets instance secondary_key to some_secondary_key' do
          set_values_instance.secondary_key.should == 'some_secondary_key'
        end
      end
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
      class SomeData < LightStore::Data
        set_prefix 'some_data'
        set_secondary_key :s_id
        set_sortable_field :super_date, :datetime
      end
      SomeData.clear_all
    end

    describe '#add_data' do
      it 'sets data' do
        new_rows = SomeData.add_data(dataset1)
      end
      it 'does not duplicate data' do
        SomeData.add_data(dataset1)
        new_rows = SomeData.add_data(dataset1)
        new_rows.should == 0
      end
    end
    describe '#get_data' do
      it 'gets data' do
        new_rows = SomeData.add_data(dataset1)
        data = SomeData.get_data
        data.size.should == new_rows
      end
      it 'gets data in proper format' do
        SomeData.add_data(dataset1)
        data = SomeData.get_data
        data.should be_a Array
        data.first.should be_a Hash
      end
      it 'gets data correctly by id' do
        SomeData.add_data(dataset1)

        # Two rows for id: 2
        data = SomeData.get_data(2)
        data.size.should == 2

        # Five rows for id: 3
        data = SomeData.get_data(3)
        data.size.should == 5
      end
    end
    describe '#get_sorted_data' do
      it 'get sorted data' do
        SomeData.add_data(dataset1)
        data = SomeData.get_sorted_data(3, :super_date, Time.new(2003), Time.new(2007))
        data.size.should == 4
      end
      it 'get sorted data includes correctly sorted values' do
        SomeData.add_data(dataset1)
        data = SomeData.get_sorted_data(3, :super_date, Time.new(2003), Time.new(2007))
        values_within_range = true
        data.each do |h|
          sorted_value = h[:super_date]
          values_between_range = false unless sorted_value >= Time.new(2003) && sorted_value <= Time.new(2007)
        end
        values_within_range.should be_true
      end
    end
    describe '#clear_all_data' do
      it 'clears all data' do
        SomeData.add_data(dataset1)
        SomeData.clear_all_data
        data = SomeData.get_data
        data.size.should == 0
      end
    end
    describe '#clear_all' do
      it 'clears all data' do
        SomeData.add_data(dataset1)
        SomeData.clear_all
        all_keys = SomeData.datastore.keys("#{SomeData.base_key}*")
        all_keys.size.should == 0
      end
    end
  end
end