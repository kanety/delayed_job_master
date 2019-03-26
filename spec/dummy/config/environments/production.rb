Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.active_record.sqlite3.represent_boolean_as_integer = true
end
