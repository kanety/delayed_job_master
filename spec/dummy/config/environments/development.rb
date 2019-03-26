Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.active_record.sqlite3.represent_boolean_as_integer = true
end
