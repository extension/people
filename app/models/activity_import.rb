# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ActivityImport < ActiveRecord::Base
  serialize :additionaldata
  attr_accessible :item, :operation, :started, :finished, :run_time, :additionaldata, :success

  HOMEPAGE_IMPORT = []

  LEARN_IMPORT    = []

  CREATE_IMPORT   = []

  ASK_IMPORT      = []


  def run_and_log(model,action)
    object = Object.const_get(model)
    self.update_attributes(started: Time.now)
    results = ''
    begin
      benchmark = Benchmark.measure do
        results = object.send(action)
      end
      finished = Time.now
      self.update_attributes(finished: finished, run_time: benchmark.real, additionaldata: results, success: true)
      success = true
    rescue StandardError => error
      self.update_attributes(additionaldata: error, success: false)
      success = false
    end
    success
  end

  def self.go_and_import(group = 'all')
    case group
    when 'all'
      list = HOMEPAGE_IMPORT + LEARN_IMPORT + CREATE_IMPORT + ASK_IMPORT
    when 'create'
      list = CREATE_IMPORT
    when 'homepage'
      list = HOMEPAGE_IMPORT
    when 'learn'
      list = LEARN_IMPORT
    when 'ask'
      list = ASK_IMPORT
    else
      return false
    end

    results = {}
    list.each do |entry|
      model = entry.keys.first
      action = entry.values.first
      import = self.create(item: model, operation: action)
      results["#{model}.#{action}"] = import.run_and_log(model,action)
    end
    results
  end

end
