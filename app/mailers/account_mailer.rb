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
      save_sent_email_for_recipient(return_email,@recipient.email,options) if @save_sent_email
    end

    return_email
  end

  def moderated_signup(options = {})
    @recipient = options[:recipient]
    @subject = "eXtension: You must be invited to get an account"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
      save_sent_email_for_recipient(return_email,@recipient.email,options) if @save_sent_email
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
      mail_options = {to: @invitation.email, subject: @subject, send_in_demo: true}
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
      mail_options = {to: @invitation.person.email, subject: @subject, send_in_demo: true}
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

  def create_colleague_google_account(options={})
    @bycolleague = options[:colleague]
    @recipient = options[:recipient]
    @subject = "eXtension: Your colleague created an eXtension Google Account for you"
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

end
