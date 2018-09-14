# frozen_string_literal: true

require "rails_helper"

feature "response form tree handling", js: true do
  include_context "response tree"

  let(:user) { create(:user) }

  let!(:form) do
    create(:form, :published,
      question_types: [
        %w[integer],
        "image",
        "multilevel_select_one",
        {
          repeating: {
            items: [
              %w[integer],
              {
                repeating: {
                  items: %w[integer]
                }
              },
              "image",
              "long_text"
            ]
          }
        }
      ])
  end

  let!(:response) do
    create(
      :response,
      form: form,
      mission: get_mission,
      user: user,
      answer_values: [
        [123],
        create(:media_image),
        %w[Plant Oak],
        {
          repeating: [
            [
              [234],
              {repeating: [[456]]},
              create(:media_image),
              "testing"
            ]
          ]
        }
      ]
    )
  end

  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(user) }

  describe "response rendering" do
    scenario "renders response with hierarchical structure" do
      visit hierarchical_response_path(response, params)

      expect_ro_value([0, 0], "123")
      expect_image([1], form.root_group.c[1].id)
      expect_ro_value([2], "Plant")
      expect_ro_value([2], "Oak")
      expect_ro_value([3, 0, 0], "234")
      expect_ro_value([3, 0, 1, 0], "456")
      expect_image([3, 0, 2], form.root_group.c[3].c[2].id)
      expect_ro_value([3, 0, 3], "testing")
    end
  end
end
