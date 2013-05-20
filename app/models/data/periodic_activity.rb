# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PeriodicActivity


  ACTIVITY_SITES = {'blogs' => 'BlogsActivity',
                    'learn' => 'EventActivity',
                    'create' => 'NodeActivity',
                    'aae' => 'QuestionActivity'}

  def self.combine_data(options = {})
    combined_results = {}
    combined_results['people'] = {}
    temp_results = {}
    combined_persons = []
    sites = options[:sites] || ACTIVITY_SITES.keys.reject{|k| k == 'people'}.sort
    months = options[:months] || 1

    # use the max date across the sites
    dates = []
    sites.each do |site|
      object = Object.const_get(ACTIVITY_SITES[site])
      dates  << object.maximum_data_date
    end
    end_date = options[:end_date] || dates.max

    combined_results['months'] = months
    combined_results['end_date'] = end_date

    sites.each do |site|
      object = Object.const_get(ACTIVITY_SITES[site])
      results = object.periodic_activity_by_person_id({months: months, :end_date => end_date})
      results.each do |key,values|
        if(key != 'people')
          combined_results["#{site}_key"] = values
        else
          results['people'].each do |id,data|
            combined_results['people'][id] ||= {}
            combined_results['people'][id]['all'] ||= {'dates' => [], 'days' => 0, 'items' => 0, 'actions' => 0}
            combined_results['people'][id]['all']['dates'] = (combined_results['people'][id]['all']['dates'] + data['dates']).uniq
            combined_results['people'][id]['all']['days'] = combined_results['people'][id]['all']['dates'].size
            combined_results['people'][id]['all']['items'] += data['items']
            combined_results['people'][id]['all']['actions'] += data['items']
            combined_results['people'][id][site] = data
          end
        end
      end
    end
    combined_results
  end

  def self.name_or_nil(item)
    item.nil? ? nil : item.name
  end

  def self.data_csv(filename,options = {})
    sites = options[:sites] || ACTIVITY_SITES.keys.reject{|k| k == 'people'}.sort
    combined_results = self.combine_data(options)
    columns = [
      'person_id',
      'idstring',
      'fullname',
      'email',
      'location'
    ]
    data_keys = ['all'] + sites.sort
    data_keys.each do |key|
      ['days','items','actions'].each do |label|
        columns << "#{key}_#{label}"
      end
    end
    CSV.open(filename,'wb') do |csv|
      headers = []
      columns.each do |column|
        headers << column
      end
      csv << headers
      combined_results['people'].each do |person_id,person_data|
        next if !(person = Person.find_by_id(person_id))
        row = []
        row << person.id
        row << person.idstring
        row << person.fullname
        row << person.email
        row << self.name_or_nil(person.location)
        data_keys.each do |key|
          ['days','items','actions'].each do |label|
            if(person_data[key] and person_data[key][label])
              row << person_data[key][label]
            else
              row << 0
            end
          end
        end        
        csv << row
      end # people
    end # csv
  end 
end