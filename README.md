# LightStore

A library for storing data about an object in spreadsheet-like format (array of hashes).

This library aims to provide an easy way to store data about objects.  Data that is typically generated with complex queries could be stored in a flat format.  This is meant to be a general purpose library, but it was created to improve performance of dynamic report generators.  This comes from an idea that each 'row' of report data could be identified by the object id and a secondary id relevant to the report.  

Data format example: `[{account_id: 1, month: '2014-11', revenue: 987.65}, {account_id: 1, month: '2014-12', revenue: 1234.56}]`

In the above example `account_id:` is a primary id and `month:` is a secondary id.

## Installation

This gem relies on redis for storage.

Add this line to your application's Gemfile:

    gem 'light_store'

And then execute:

    $ bundle install

### In rails

Add an initializer:

```ruby
LightStore.configure do |config|
  config.redis = Redis.new
end
```

Define a class:

```ruby
class RevenueReport < LightStore::Data
 set_prefix 'revenue_report'
 set_primary_key :id       # default
 set_secondary_key :month  # required
 
 set_sortable_field :month, :datetime
 set_sortable_field :revenue, :float
 set_sortable_field :number_of_orders, :integer
end
```

Adding data:

```ruby
data = [
  {id: 1, month: '2012-01', revenue: 1234.56, number_of_orders: 10},
  {id: 1, month: '2012-02', revenue: 2345.56, number_of_orders: 20},
  {id: 1, month: '2012-03', revenue: 3245.56, number_of_orders: 30},
  {id: 1, month: '2012-04', revenue: 2435.56, number_of_orders: 20},
  {id: 2, month: '2012-01', revenue: 1234.56, number_of_orders: 10},
  {id: 2, month: '2012-02', revenue: 2234.56, number_of_orders: 20},
  {id: 2, month: '2012-03', revenue: 3234.56, number_of_orders: 30},
  {id: 2, month: '2012-04', revenue: 2234.56, number_of_orders: 20},
]
RevenueReport.add_data(data)
```

Getting all data:
```ruby
data = RevenueReport.get_data()
```

Getting data for id:
```ruby
data = RevenueReport.get_data(2)
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
