class Interface
  include Mongoid::Document
  include Mongoid::Timestamps

  field :infra_id, type: Integer
  field :org_id, type: Integer
  field :name, type: String
  field :cmdb, type: Hash
end
