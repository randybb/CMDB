class Subnet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :infrid, type: Integer
  field :infra_id, type: Integer
  field :org_id, type: Integer
  field :name, type: String
  field :cmdb, type: Hash
end
