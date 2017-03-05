class Equipment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :site_id, type: Integer
  field :infra_id, type: Integer
  field :org_id, type: Integer
  field :name, type: String
  field :alias, type: String
  field :cmdb, type: Hash
  field :timestamps, type: Hash
  field :file_config, type: BSON::Code
  field :device, type: Hash
end
