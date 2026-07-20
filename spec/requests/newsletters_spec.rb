# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Newsletters" do
  let(:valid_params) do
    { subscriber: { email: "new@example.com", consent: "1", source: "home" } }
  end

  describe "POST /newsletter" do
    context "when consent is given and email is new" do
      it "creates a Subscriber record" do
        expect { post newsletters_path, params: valid_params }.to change(Subscriber, :count).by(1)
      end

      it "leaves the subscriber in a pending (unconfirmed) state" do
        post newsletters_path, params: valid_params

        expect(Subscriber.last.confirmed?).to be false
      end

      it "stores the consent source from the form" do
        post newsletters_path, params: valid_params

        expect(Subscriber.last.consent_source).to eq("home")
      end

      it "enqueues a confirmation email to the submitted address" do
        expect { post newsletters_path, params: valid_params }
          .to have_enqueued_mail(NewsletterMailer, :confirmation)
      end

      it "redirects with a success notice" do
        post newsletters_path, params: valid_params

        expect(flash[:notice]).to eq("Check your email for a confirmation link!")
      end
    end

    context "when consent is not given" do
      let(:no_consent_params) { { subscriber: { email: "new@example.com", consent: "0", source: "home" } } }

      it "does not create a Subscriber record" do
        expect { post newsletters_path, params: no_consent_params }.not_to change(Subscriber, :count)
      end

      it "redirects with a consent-required alert" do
        post newsletters_path, params: no_consent_params

        expect(flash[:alert]).to eq("Please accept the consent checkbox.")
      end
    end

    context "when consent param is entirely absent" do
      let(:missing_consent_params) { { subscriber: { email: "new@example.com", source: "home" } } }

      it "does not create a Subscriber record" do
        expect { post newsletters_path, params: missing_consent_params }.not_to change(Subscriber, :count)
      end
    end

    context "when the email is already confirmed and active" do
      before { create(:subscriber, :confirmed, email: "existing@example.com") }

      it "does not create a duplicate Subscriber" do
        expect do
          post newsletters_path, params: { subscriber: { email: "existing@example.com", consent: "1", source: "home" } }
        end.not_to change(Subscriber, :count)
      end

      it "redirects with an 'already subscribed' notice" do
        post newsletters_path, params: { subscriber: { email: "existing@example.com", consent: "1", source: "home" } }

        expect(flash[:notice]).to eq("You're already subscribed — thanks!")
      end

      it "does not enqueue another confirmation email" do
        expect do
          post newsletters_path, params: { subscriber: { email: "existing@example.com", consent: "1", source: "home" } }
        end.not_to have_enqueued_mail(NewsletterMailer, :confirmation)
      end
    end

    context "when re-subscribing after unsubscribing" do
      let!(:subscriber) { create(:subscriber, :unsubscribed, email: "returning@example.com") }

      it "does not create a new Subscriber row" do
        expect do
          post newsletters_path, params: { subscriber: { email: "returning@example.com", consent: "1", source: "footer" } }
        end.not_to change(Subscriber, :count)
      end

      it "clears unsubscribed_at on the existing record" do
        post newsletters_path, params: { subscriber: { email: "returning@example.com", consent: "1", source: "footer" } }

        expect(subscriber.reload.unsubscribed_at).to be_nil
      end

      it "clears confirmed_at so the subscriber re-enters the pending flow" do
        post newsletters_path, params: { subscriber: { email: "returning@example.com", consent: "1", source: "footer" } }

        expect(subscriber.reload.confirmed_at).to be_nil
      end

      it "enqueues a fresh confirmation email" do
        expect do
          post newsletters_path, params: { subscriber: { email: "returning@example.com", consent: "1", source: "footer" } }
        end.to have_enqueued_mail(NewsletterMailer, :confirmation)
      end
    end

    context "when email is already pending (signed up but not yet confirmed)" do
      before { create(:subscriber, :pending, email: "pending@example.com") }

      it "does not create a new Subscriber row" do
        expect do
          post newsletters_path, params: { subscriber: { email: "pending@example.com", consent: "1", source: "home" } }
        end.not_to change(Subscriber, :count)
      end

      it "enqueues a fresh confirmation email" do
        expect do
          post newsletters_path, params: { subscriber: { email: "pending@example.com", consent: "1", source: "home" } }
        end.to have_enqueued_mail(NewsletterMailer, :confirmation)
      end
    end
  end

  describe "GET /newsletter/confirm" do
    context "with a valid token" do
      let!(:subscriber) { create(:subscriber, :pending) }

      it "sets confirmed_at on the subscriber" do
        get newsletter_confirm_path(token: subscriber.confirmation_token)

        expect(subscriber.reload.confirmed_at).not_to be_nil
      end

      it "returns a 200 OK" do
        get newsletter_confirm_path(token: subscriber.confirmation_token)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid token" do
      it "redirects to root" do
        get newsletter_confirm_path(token: "totally-bogus-token")

        expect(response).to redirect_to(root_path)
      end

      it "sets an invalid-link alert" do
        get newsletter_confirm_path(token: "totally-bogus-token")

        expect(flash[:alert]).to eq("Confirmation link is invalid or has already been used.")
      end
    end
  end

  describe "GET /newsletter/unsubscribe" do
    context "with a valid token" do
      let!(:subscriber) { create(:subscriber, :confirmed) }

      it "sets unsubscribed_at on the subscriber" do
        get newsletter_unsubscribe_path(token: subscriber.confirmation_token)

        expect(subscriber.reload.unsubscribed_at).not_to be_nil
      end

      it "returns a 200 OK" do
        get newsletter_unsubscribe_path(token: subscriber.confirmation_token)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid token" do
      it "redirects to root" do
        get newsletter_unsubscribe_path(token: "bogus")

        expect(response).to redirect_to(root_path)
      end

      it "sets an invalid-link alert" do
        get newsletter_unsubscribe_path(token: "bogus")

        expect(flash[:alert]).to eq("Unsubscribe link is invalid.")
      end
    end
  end
end
