# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ActivityImport < ActiveRecord::Base
  serialize :additionaldata
  attr_accessible :item, :operation, :started, :finished, :run_time, :additionaldata, :success

  PUBLISH_IMPORT = [{'AppActivity' => 'publish_post_activity_import'},
                    {'AppActivity' => 'publish_comment_activity_import'}]

  HOMEPAGE_IMPORT = [{'AppActivity' => 'homepage_post_activity_import'},
                    {'AppActivity' => 'homepage_comment_activity_import'}]

  LEARN_IMPORT    = [{'AppActivity' => 'learn_event_activity_import'},
                    {'AppActivity' => 'learn_versions_activity_import'}]

  CREATE_IMPORT   = [{'AppActivity' => 'create_revisions_activity_import'},
                    {'AppActivity' => 'create_workflow_events_activity_import'},
                    {'AppActivity' => 'create_comments_activity_import'}]

  ASK_IMPORT      = [{'AppActivity' => 'ask_questionevent_activity_import'}]


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
      list = PUBLISH_IMPORT + HOMEPAGE_IMPORT + LEARN_IMPORT + CREATE_IMPORT + ASK_IMPORT
    when 'create'
      list = CREATE_IMPORT
    when 'publish'
      list = PUBLISH_IMPORT
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
