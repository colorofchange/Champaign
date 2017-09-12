class PensionEmailSender
  def self.run(page_id, params)
    new(page_id, params).run
  end

  def initialize(page_id, params)
    @plugin ||= Plugins::EmailPension.find_by(page_id: page_id)
    @page = Page.find(page_id)
    @params = params.slice(:body, :subject, :to_email, :target_name, :from_name, :from_email)
  end

  def run
    EmailSender.run(
      id:  @page.slug,
      subject:    @params[:subject],
      body:       @params[:body],
      to:         to_emails,
      from_name:  @params[:from_name],
      # Use member's email only if #use_email_address is true
      from_email: @params[:from_email],
      # Don't reply-to members email address if use_email_address is false
      reply_to: [{ name: @plugin.name_from, address: @plugin.email_from },
                 { name: @params[:from_name], address: @params[:from_email] }]
    )
  end

  private

  def to_emails
    if @plugin.test_email_address.blank?
      { name: @params[:target_name], address: @params[:to_email] }
    else
      { name: 'Test', address: @plugin.test_email_address }
    end
  end
end