require "spec_helper"

# Using request spec b/c Authlogic won"t work with controller spec
describe PasswordResetsController, type: :request do
  let(:user) { create(:user) }

  context "if not logged in" do
    it "new password reset page should load" do
      get new_password_reset_path
      expect(response).to be_success
    end

    it "submitting password reset form should reset perishable token and send email" do
      old_tok = user.perishable_token

      # Should be redirected to login
      assert_difference("ActionMailer::Base.deliveries.size", +1) do
        post password_resets_path, {password_reset: {email: user.email}}
      end

      expect(old_tok).not_to eq user.reload.perishable_token
      expect(response).to redirect_to(login_url)
      follow_redirect!
    end
  end

  context "if already logged in" do
    let(:user2) { create(:user) }

    before do
      login(user)
      user2.reset_perishable_token!
    end

    it "attempting to load edit should logout existing user" do
      get edit_password_reset_path(id: user2.perishable_token)
      expect(controller.current_user).to be_nil
    end
  end

  context "when generating password reset" do
    context "in admin mode" do
      let(:admin) { create(:admin) }

      before do
        login(admin)
      end

      it "should generate correct email" do
        # Make sure email gets sent
        assert_difference("ActionMailer::Base.deliveries.size", +1) do
          # Create a new user, sending password instr to email
          post users_path(mode: "admin", mission_name: nil), "user" => {
            "name" => "Alberto Ooooh",
            "login" => "aooooh",
            "email" => "foo@example.com",
            "assignments_attributes" => {
              "1" => {
                "id" => "",
                "_destroy" => "false",
                "mission_id" => get_mission.id,
                "role" => "observer"
              }
            },
            "reset_password_method" => "email"
          }
          expect(response).to redirect_to users_path(mode: "admin")
          follow_redirect!
          expect(response).to be_success
        end

        # Make sure url is correct
        email = ActionMailer::Base.deliveries.last
        expect(email.body.to_s).to match %r{^https?://.+/en/password-resets/\w+/edit$}

        # Ensure no missing translations
        expect(email.body.to_s).not_to match /translation_missing/
      end
    end
  end
end
