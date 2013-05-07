# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ProfilePublicSetting < ActiveRecord::Base
  attr_accessible :person, :person_id, :item, :is_public

  belongs_to :person
  
  
  KNOWN_ITEMS = ['email','phone','title','position','institution','location','county','interests','time_zone','biography']
  
  ITEM_LABELS =  {'email' => 'Email Address',
                  'phone' => 'Phone Number',
                  'title' => 'Title',
                  'position' => 'Position',
                  'institution' => 'Institution',
                  'location' => 'Location',
                  'county' => 'County',
                  'interests' => 'Interests',
                  'time_zone' => 'Time zone',
                  'biography' => 'Biography'}
                        
  scope :is_public, where(is_public: true)
                        
  def self.find_or_create_by_person_and_item(person,item,is_public = false)  
    if(setting = self.where(person_id: person.id).where(item: item).first)
      return setting
    else
      return self.create(person_id: person.id, item: item, is_public: is_public)
    end
  end
      
  

end