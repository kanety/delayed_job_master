# simplecov
require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_support/all'
require 'delayed_job_active_record'
require 'delayed_job_master'

require_relative 'delayed_job_master_helper'
