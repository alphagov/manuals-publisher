module FinderGeneratorHelper
  def self.add_and_sort_hash hash, key, value
    hash = hash.merge(key => value)
    hash = hash.sort_by { |k,v| k }
    mappings = hash.map {|k,v| %Q|    "#{k}" => #{v},|}.join("\n")
  end

  def self.add_mapping file, key, value, generator, map_name, hash
    mappings = add_and_sort_hash hash, key, value

    generator.gsub_file file, /  #{map_name} = \{\n.+  \}\.freeze\n/m do
      "  #{map_name} = {\n" + mappings + "\n  }.freeze\n"
    end
  end

  def self.remove_mapping file, key, value, generator
    mapping = %[    "#{key}" => #{value},\n]
    generator.behavior = :invoke # need to do this for gsub_file to work
    generator.gsub_file file, mapping, ""
    generator.gsub_file file, mapping.sub(",",""), ""
    generator.behavior = :revoke # reset to revoke
  end

  def self.update_mapping file, key, value, generator, map_name, hash
    case generator.behavior
    when :invoke
      FinderGeneratorHelper::add_mapping file, key, value, generator, map_name, hash
    when :revoke
      FinderGeneratorHelper::remove_mapping file, key, value, generator
    end
  end

end

class FinderGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  class_option :title, desc: "Title of finder",
      type: :string, required: true

  class_option :document_attributes, desc: "Attributes to index",
      type: :string, required: true

  class_option :attribute_placeholders, desc: "Placeholder text for display",
      type: :string, required: true

  class_option :rummager_types, desc: "Attribute types for rummager configuration",
      type: :string, required: true

  class_option :organisation_slug, desc: "Slug for organisation",
      type: :string, required: true

  class_option :display_name, desc: "Finder name for display",
      type: :string, required: true

  class_option :display_description, desc: "Finder description for display",
      type: :string, required: true

  class_option :document_noun, desc: "noun for a single document",
      type: :string, required: true

  class_option :content_id, desc: "id for finder",
      type: :string, required: true

  class_option :organisation_id, desc: "id for finder organisation",
      type: :string, required: true

  class_option :preview_only, desc: "true if only want finder in a preview environment",
      type: :boolean

  def setup_allowed_values
    hash = JSON.parse( File.open("./finders/schemas/#{name.pluralize}.json").read )
    allowed_values = {}
    hash['facets'].each do |facet|
      key = facet['key']
      allowed_values[key] = facet['allowed_values'] if facet['allowed_values']
    end
    @allowed_values = allowed_values
  end

  def setup_attributes
    @document_attributes = options[:document_attributes].split(",")
    @rummager_types = options[:rummager_types].split(",")
    @placeholders = options[:attribute_placeholders].split(",")
  end

  def populate_attribute_labels
    hash = JSON.parse( File.open("./finders/schemas/#{name.pluralize}.json").read )
    labels = {}
    hash['facets'].each do |facet|
      key = facet['key']
      labels[key] = facet['name']
    end
    @attribute_labels = labels
  end

  def create_model
    create_file "app/models/#{name.underscore}.rb", <<-FILE
require "document_metadata_decorator"

class #{class_name} < DocumentMetadataDecorator
  set_extra_field_names [
    #{ @document_attributes.map {|a| ":#{a}"}.join(",\n    ") }
  ]
end
FILE
  end

  def add_to_application_finders
    inject_into_file "app/controllers/application_controller.rb",
      after: "  def finders\n    {\n" do
      <<-INSERT
      "#{name.pluralize}" => {
        document_type: "#{name.underscore}",
        title: "#{options[:title]}",
      },
        INSERT
    end
  end

  def create_controller
    create_file "app/controllers/#{plural_name}_controller.rb", <<-FILE
class #{class_name.pluralize}Controller < AbstractDocumentsController
end
FILE
  end

  def create_indexable_formatter
    template "indexable_formatter.rb.erb",
        "app/exporters/formatters/#{name.underscore}_indexable_formatter.rb"
  end

  def create_alert_formatter
    template "publication_alert_formatter.rb.erb",
        "app/exporters/formatters/#{name.underscore}_publication_alert_formatter.rb"
  end

  def create_validator
    template "validator.rb.erb",
        "app/models/validators/#{name.underscore}_validator.rb"
  end

  def create_view_adapter
    template "view_adapter.rb.erb",
        "app/view_adapters/#{name.underscore}_view_adapter.rb"
  end

  def add_to_view_adapter_registry
    FinderGeneratorHelper::update_mapping "app/view_adapters/view_adapter_registry.rb",
      name.underscore,
      "#{class_name}ViewAdapter",
      self,
      "VIEW_ADAPTER_MAP",
      ViewAdapterRegistry::VIEW_ADAPTER_MAP
  end

  def create_view
    inputs = @document_attributes.each_with_index.map do |a, i|
      type = @rummager_types[i]
      placeholder = @placeholders[i]
      label = @attribute_labels[a]
      case type
      when /identifier\z/
        if @allowed_values.has_key?(a)
          "    <%= f.select :#{a}, f.object.facet_options(:#{a}), { label: \"#{label}\" }, { class: 'form-control' } %>"
        elsif placeholder
          "    <%= f.text_field :#{a}, label: \"#{label}\", placeholder: '#{placeholder}', class: 'form-control' %>"
        else
          "    <%= f.text_field :#{a}, label: \"#{label}\", class: 'form-control' %>"
        end
      when /identifiers\z/
        "    <%= f.select :#{a}, f.object.facet_options(:#{a}), { label: \"#{label}\" }, { class: 'select2', multiple: true, data: { placeholder: '#{placeholder}' } } %>"
      when 'date'
        "    <%= f.text_field :#{a}, label: \"#{label}\", placeholder: '#{placeholder}', class: 'form-control' %>"
      else
        raise "Unknown rummager type: #{type} for: #{a}"
      end
    end

    create_file "app/views/#{plural_name.underscore}/_form.html.erb",
<<-FILE
<div class="col-md-8">
  <%= form_for document do |f| %>
    <%= render partial: "shared/form_errors", locals: { object: document } %>
    <%= render partial: "shared/form_fields", locals: { f: f } %>
    <%= render partial: "shared/form_preview" %>

#{inputs.join("\n")}

    <%= render partial: "specialist_documents/minor_major_update_fields", locals: { f: f, document: document } %>

    <div class="actions">
      <button name="save" class="btn btn-success">Save as draft</button>
    </div>
  <% end %>
</div>

<%= render partial: "specialist_documents/attachments_form", locals: { document: document } %>

<%= render partial: "specialist_documents/js_preview", locals: { document: document, form_namespace: "#{name.underscore}" } %>
FILE
  end

  def add_to_permission_checker
    inject_into_file "app/lib/permission_checker.rb",
      after: "  case format\n" do
      <<-INSERT
    when "#{name.underscore}"
      ["#{options[:organisation_slug]}"]
INSERT
    end
  end

  def create_observers_registry
    template "observers_registry.rb.erb",
        "app/observers/#{name.underscore}_observers_registry.rb"
  end

  def add_to_specialist_publisher
    FinderGeneratorHelper::update_mapping "app/lib/specialist_publisher.rb",
      name.underscore,
      "#{class_name}ObserversRegistry",
      self,
      "OBSERVER_MAP",
      SpecialistPublisher::OBSERVER_MAP
  end

  def add_to_specialist_publisher_wiring
    inject_into_file "app/lib/specialist_publisher_wiring.rb",
      before: "  define_instance(:markdown_attachment_renderer) {" do
      <<-INSERT
  define_factory(:#{name.underscore}_builder) {
    SpecialistDocumentBuilder.new("#{name.underscore}",
      get(:validatable_document_factories).#{name.underscore}_factory)
  }

INSERT
    end
    inject_into_file "app/lib/specialist_publisher_wiring.rb",
      before: "  define_singleton(:organisations_api) {" do
      <<-INSERT
  define_singleton(:#{name.underscore}_finder_schema) {
    FinderSchema.new(Rails.root.join("finders/schemas/#{name.pluralize}.json"))
  }

INSERT
    end
  end

  def create_metadata
    metadata = {
      content_id: "#{options[:content_id]}",
      base_path: "/#{name.pluralize}",
      format_name: "#{options[:display_name].singularize}",
      name: "#{options[:display_name]}",
      description: "#{options[:display_description]}",
      beta: true,
      filter: {
        document_type: "#{name.underscore}"
      },
      show_summaries: true,
      organisations: ["#{options[:organisation_id]}"]
    }

    metadata.merge!(preview_only: true) if options[:preview_only]

    metadata_file = "finders/metadata/#{plural_name}.json"
    create_file metadata_file, "#{JSON.pretty_generate(metadata)}\n"
  end

  def create_indexable_formatter_spec
    template "indexable_formatter_spec.rb.erb",
        "spec/exporters/formatters/#{name.underscore}_indexable_formatter_spec.rb"
  end

  def create_model_spec
    create_file "spec/models/#{name.underscore}_spec.rb", <<-FILE
require "fast_spec_helper"
require "#{name.underscore}"

RSpec.describe #{class_name} do

  it "is a DocumentMetadataDecorator" do
    doc = double(:document)
    expect(#{class_name}.new(doc)).to be_a(DocumentMetadataDecorator)
  end

end
FILE
  end

  def add_to_document_factory_registry
    file = "app/models/document_factory_registry.rb"
    inject_into_file file,
      before: %|\nrequire "builders/manual_document_builder"| do
      %|require "validators/#{name.underscore}_validator"
|
    end

    inject_into_file file,
      before: %|\nclass DocumentFactoryRegistry| do
      %|require "#{name.underscore}"
|
    end

    inject_into_file file,
      before: %|\n  def manual_with_documents| do
      <<-INSERT

  def #{name.underscore}_factory
    ->(*args) {
      ChangeNoteValidator.new(
        #{class_name}Validator.new(
          #{class_name}.new(
            SpecialistDocument.new(
              SlugGenerator.new(prefix: "#{name.pluralize}"),
              *args,
            ),
          )
        )
      )
    }
  end
INSERT
    end

  end

  def add_to_schema_index_in_rummager
    inject_into_file "../rummager/config/schema/indexes/mainstream.json",
      before: "\n  ]" do
      %|,\n    "#{name.underscore}"|
    end
  end

  def create_schema_in_rummager
    hash = {
      fields: @document_attributes,
      allowed_values: @allowed_values
    }

    schema_file = "../rummager/config/schema/document_types/#{name.underscore}.json"
    create_file schema_file, "#{JSON.pretty_generate(hash)}\n"
  end

  def add_to_field_definitions_in_rummager
    case behavior
    when :invoke
      definitions_file = "../rummager/config/schema/field_definitions.json"
      hash = JSON.parse( File.open(definitions_file).read )
      new_attributes = []
      @document_attributes.each_with_index do |a,i|
        new_attributes << [a, @rummager_types[i]] unless hash.has_key?(a)
      end
      definitions = {}
      new_attributes.each do |attribute, type|
        definitions[attribute] = { type: type }
      end
      definitions_json = ",\n  " + JSON.pretty_generate(definitions).sub('{','').chomp('}').strip

      inject_into_file definitions_file, before: "\n}\n" do
        definitions_json
      end
    when :revoke
      # not revokable
    end
  end

end
