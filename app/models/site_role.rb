#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class SiteRole < ActiveRecord::Base
  attr_accessible :permissable_id, :permissable_type, :site, :permissable, :site_id, :permission

  belongs_to :site
  belongs_to :permissable, polymorphic: true

  # global roles
  ADMINISTRATOR = 1
  EDITOR        = 2
  WRITER        = 3
  READER        = 4


  def self.wordpress_label(role)
    case role
    when ADMINISTRATOR
      'administrator'
    when EDITOR
      'editor'
    when WRITER
      'author'
    when READER
      'follower'
    else
      'follower'
    end
  end

  def self.wordpress_user_level(role)
    case role
    when ADMINISTRATOR
      10
    when EDITOR
      7
    when WRITER
      2
    else
      0
    end
  end

  def self.role_to_s(role)
    self.code_to_constant_string(role)
  end

  def self.code_to_constant_string(code)
    constantslist = self.constants
    constantslist.each do |c|
      value = self.const_get(c)
      if(value.is_a?(Fixnum) and code == value)
        return c.to_s.downcase
      end
    end

    # if we got here?  return nil
    return nil
  end

end
