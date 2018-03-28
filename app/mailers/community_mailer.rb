# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CommunityMailer < BaseMailer

  def join(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague has joined the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def pending(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague wants to join the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end


  def leave(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague has left the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def accept_invitation(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague has accepted an invitation to join the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def decline_invitation(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague has accepted an invitation to join the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def invited(options = {})
    @community = options[:community]
    @bycolleague = options[:connector]
    @person = options[:person]
    @recipient = options[:recipient]
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = options[:connectiontype]
    if(connectiontype == 'leader')
      @invited_text = @community.is_institution? ? 'member of the insititutional team' : 'leader'
    else
      @invited_text = 'member'
    end

    @subject = "eXtension: A colleague is invited to the #{@community.name} community"

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def invited_person(options = {})
    @community = options[:community]
    @bycolleague = options[:connector]
    @recipient = options[:recipient]
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = options[:connectiontype]
    if(connectiontype == 'leader')
      @invited_text = @community.is_institution? ? 'member of the insititutional team' : 'leader'
    else
      @invited_text = 'member'
    end

    @subject = "eXtension: You have been invited to the #{@community.name} community"

    if(!@recipient.email.blank?)
      mail_options = {to: @recipient.email, subject: @subject}
      mail_options[:cc] = @bycolleague.email if !@bycolleague.email.blank?
      return_email = create_mail(mail_options)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def added(options = {})
    @community = options[:community]
    @bycolleague = options[:connector]
    @person = options[:person]
    @recipient = options[:recipient]
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = options[:connectiontype]
    if(connectiontype == 'leader')
      @added_text = @community.is_institution? ? 'member of the insititutional team' : 'leader'
    else
      @added_text = 'member'
    end

    @subject = "eXtension: A colleague was added to the #{@community.name} community"

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def added_person(options = {})
    @community = options[:community]
    @bycolleague = options[:connector]
    @recipient = options[:recipient]
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = options[:connectiontype]
    if(connectiontype == 'leader')
      @added_text = @community.is_institution? ? 'member of the insititutional team' : 'leader'
    else
      @added_text = 'member'
    end

    @subject = "eXtension: You have been added to the #{@community.name} community"

    if(!@recipient.email.blank?)
      mail_options = {to: @recipient.email, subject: @subject}
      mail_options[:cc] = @bycolleague.email if !@bycolleague.email.blank?
      return_email = create_mail(mail_options)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end


  def removed(options = {})
    @community = options[:community]
    @bycolleague = options[:connector]
    @person = options[:person]
    @recipient = options[:recipient]
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = options[:connectiontype]
    if(connectiontype == 'leader')
      @removed_text = @community.is_institution? ? 'member of the insititutional team' : 'leader'
    elsif(connectiontype == 'pending')
      @removed_text = 'pending member'
    else
      @removed_text = 'member'
    end

    @subject = "eXtension: A colleague was removed from the #{@community.name} community"

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def removed_person(options = {})
    @community = options[:community]
    @bycolleague = options[:connector]
    @recipient = options[:recipient]
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = options[:connectiontype]
    if(connectiontype == 'leader')
      @removed_text = @community.is_institution? ? 'member of the insititutional team' : 'leader'
      @subject = "eXtension: You have been removed as a leader of the #{@community.name} community"
    elsif(connectiontype == 'pending')
      @removed_text = 'pending member'
      @subject = "eXtension: You have been removed from the #{@community.name} community"
    else
      @removed_text = 'member'
      @subject = "eXtension: You have been removed from the #{@community.name} community"
    end

    if(!@recipient.email.blank?)
      mail_options = {to: @recipient.email, subject: @subject}
      mail_options[:cc] = @bycolleague.email if !@bycolleague.email.blank?
      return_email = create_mail(mail_options)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def not_pending
    #TODO ?
  end

end
