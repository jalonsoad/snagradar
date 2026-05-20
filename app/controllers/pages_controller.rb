class PagesController < ApplicationController
  layout "marketing"

  def home;     end
  def features; end
  def pricing;  end
  def about;    end
  def privacy;  end
  def terms;    end

  def contact
    @contact = ContactForm.new
  end

  def submit_contact
    @contact = ContactForm.new(contact_params)

    if @contact.valid?
      # TODO: deliver via ContactMailer / store the lead. For now: thank-you flash.
      redirect_to contact_path, notice: "Thanks #{@contact.name.split.first} — we'll be in touch within 4 hours."
    else
      flash.now[:alert] = "There's a couple of fields to check."
      render :contact, status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.require(:contact_form).permit(:name, :company, :email, :phone, :interest, :message, :terms_accepted)
  end
end
