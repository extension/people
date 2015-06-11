# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Interest < ActiveRecord::Base
  attr_accessible :name

  has_many :person_interests
  has_many :people, through: :person_interests

  scope :used, -> {joins(:person_interests)
                   .select("#{self.table_name}.*, COUNT(person_interests.id) AS interest_count")
                   .group("#{self.table_name}.id")
                   .having("interest_count > 0")}  
  def name=(name)
    write_attribute(:name, self.class.normalizename(name))
  end

  # normalize interest names 
  # convert whitespace to single space, underscores to space, yank everything that's not alphanumeric : - or whitespace (which is now single spaces)   
  def self.normalizename(name)
    # make an initial downcased copy - don't want to modify name as a side effect
    returnstring = name.downcase
    # now, use the replacement versions of gsub and strip on returnstring
    # convert underscores to spaces
    returnstring.gsub!('_',' ')
    # get rid of anything that's not a "word", not space, not : and not - 
    returnstring.gsub!(/[^\w :-]/,'')
    # reduce multiple spaces to a single space
    returnstring.gsub!(/ {2,}/,' ')
    # remove leading and trailing whitespace
    returnstring.strip!
    returnstring
  end


  def self.find_or_create_by_name(name)
    if(!(interest = self.find_by_name(self.normalizename(name))))
      interest = self.create(name: name)
    end
    interest
  end

end