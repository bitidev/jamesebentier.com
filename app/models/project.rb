# frozen_string_literal: true

# This is the Project model that represents the projects that James Ebentier is working on.
class Project < ApplicationRecord
  declare_schema do
    string :slug,   limit: 255,  null: false, validates: { presence: true, uniqueness: true }, index: { unique: true }
    string :title,  limit: 1024, null: false, validates: { presence: true }
    string :status, limit: 255, null: false,  validates: { presence: true, inclusion: { in: %w[Beta Live] } },
                    default: 'Beta'
    string :url,    limit: 1024, null: false, validates: { presence: true }
    string :image,  limit: 1024, null: false, validates: { presence: true }
    text   :description, null: false, validates: { presence: true }
  end
end
