class Organization
  include Mongoid::Document
  include Mongoid::Timestamps

  field :infra_id, type: Integer
  field :name, type: String
end
