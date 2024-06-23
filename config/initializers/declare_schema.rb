# frozen_string_literal: true

DeclareSchema.default_schema do
  timestamps
  optimistic_lock
end

DeclareSchema.max_index_and_constraint_name_length = nil
DeclareSchema.default_generate_foreign_keys        = false

# The following are patches made directly to the DeclareSchema gem as
# it appears to be majorily built for a MySQL database, but we're using
# PostgreSQL. These patches should be contributed back to the gem.

module DeclareSchemaColumnPatch # rubocop:disable Style/Documentation
  extend ActiveSupport::Concern

  module ClassMethods # rubocop:disable Style/Documentation
    def deserialize_default_value(column, type, default_value)
      super
    rescue StandardError => e
      Rails.logger.info "Unable to deserialize default value for column #{column.name} of type #{type.inspect} with default value #{default_value.inspect}: #{e.message}"
      nil
    end
  end
end

module DeclareSchemaMigratorPatch # rubocop:disable Style/Documentation
  extend ActiveSupport::Concern

  def table_options_for_model(model)
    if ActiveRecord::Base.connection.class.name.include?('PostgreSQLAdapter')
      {}
    else
      super
    end
  end
end

module DeclareSchema
  module Model
    module ClassMethods # rubocop:disable Style/Documentation
      def _add_index_for_field(column_name, args, **options)
        return unless (index_config = options.delete(:index))

        index_opts = index_config.is_a?(Hash) ? index_config : {}
        index_opts[:unique] ||= args.include?(:unique) || !!options.delete(:unique) # rubocop:disable Style/DoubleNegation

        # support index: true declaration
        index_opts[:name] = index_config unless index_config == true || index_config.is_a?(Hash)
        index([column_name], **index_opts)
      end
    end
  end
end

require 'generators/declare_schema/migration/migrator'
Generators::DeclareSchema::Migration::Migrator.prepend DeclareSchemaMigratorPatch
DeclareSchema::Model::Column.prepend DeclareSchemaColumnPatch
