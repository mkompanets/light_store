# LightStore

A library for storing data about an object in spreadsheet-like format (array of hashes).

This library aims to provide an easy way to store report data about objects.  Data that is typically generated with complex queries and methods could be stored in a flat and accessible format.  This is meant to be a general purpose library, but it was created to improve performance of dynamic report generators.  This comes from an idea that each 'row' of report data could be identified by the object id and a secondary id relevant to the report.  

Data format example: `[{account_id: 1, month: '2014-11', revenue: 987.65}, {account_id: 1, month: '2014-12', revenue: 1234.56}]`.

In the above example `account_id:` is a primary id and `month:` is a secondary id.

## Installation

This gem relies on redis for storage.

Add this line to your application's Gemfile:

    gem 'light_store'

And then execute:

    $ bundle install

### In rails

Add an initializer.

```ruby
LightStore.configure do |config|
  config.redis = Redis.new
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
