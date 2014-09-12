class Equipment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :id, type: Integer
  field :site_id, type: Integer
  field :_id, type: String, default: -> { id }
  field :org_id, type: Integer
  field :name, type: String
  field :alias, type: String
  field :cmdb, type: Hash
  field :timestamps, type: Hash
  field :file_config, type: BSON::Code
  field :device, type: Hash
end
