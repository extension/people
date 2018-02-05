# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AccountMailer < BaseMailer

  def signup(options = {})
    @recipient = options[:recipient]
    @subject = "eXtension: Please confirm your email address"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def confirm(options = {})
    @recipient = options[:recipient]
    @subject = "eXtension: Please confirm your email address"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end


  def welcome(options={})
    @recipient = options[:recipient]
    @subject = "eXtension: Welcome!"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def account_reminder(options={})
    @recipient = options[:recipient]
    @subject = "eXtension: Check out our new services!"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: false)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def invitation(options={})
    @invitation = options[:invitation]
    @subject = "eXtension: You have been invited to join us"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@invitation.email.blank?)
      mail_options = {to: @invitation.email, subject: @subject}
      mail_options[:cc] = @invitation.person.email if !@invitation.person.email.blank?
      return_email = create_mail(mail_options)
      save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
    end

    return_email
  end

  def invitation_accepted(options={})
    @invitation = options[:invitation]
    @subject = "eXtension: Your invitation to eXtension has been accepted"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@invitation.person.email.blank?)
      mail_options = {to: @invitation.person.email, subject: @subject}
      mail_options[:cc] = @invitation.colleague.email if (@invitation.colleague && !@invitation.colleague.email.blank?)
      return_email = create_mail(mail_options)
      save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
    end

    return_email
  end

  def profile_update(options={})
    @bycolleague = options[:colleague]
    @recipient = options[:recipient]
    @what_changed = options[:what_changed]
    @subject = "eXtension: Your profile was updated by a colleague"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      mail_options = {to: @recipient.email, subject: @subject}
      mail_options[:cc] = @bycolleague.email if !@bycolleague.email.blank?
      return_email = create_mail(mail_options)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def password_reset_request(options = {})
    @recipient = options[:recipient]
    @subject = "eXtension: Please confirm your email address"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def password_reset(options = {})
    @recipient = options[:recipient]
    @subject = "eXtension: Your password has been reset"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

  def colleague_download_available(options = {})
    @browse_filter = options[:browse_filter]
    @recipient = options[:recipient]
    @subject = "eXtension: Your download is now available"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end


  def google_group_migration(options = {})
    @recipient = options[:recipient]
    @google_group = options[:google_group]
    @community = @google_group.community
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    connectiontype = @google_group.connectiontype
    if(connectiontype == 'leaders')
      @recipient_connection = @community.is_institution? ? 'member of the insititutional team' : 'leader'
    else
      @recipient_connection = 'member'
    end

    @subject = "eXtension: Your Google Group has a new email address: #{@google_group.group_email_address}"

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email,
                                 subject: @subject,
                                 return_path: Settings.google_support_contact)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end

    return_email
  end

end
