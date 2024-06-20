# frozen_string_literal: true

DeclareSchema.default_schema do
  timestamps
  optimistic_lock
end

DeclareSchema.default_charset                      = "utf8"
DeclareSchema.default_collation                    = "ucs_basic"
DeclareSchema.default_text_limit                   = 0xffff
DeclareSchema.default_string_limit                 = 255
DeclareSchema.max_index_and_constraint_name_length = nil
