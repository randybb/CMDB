class Line
  include Mongoid::Document
  include Mongoid::Timestamps

  field :id, type: Integer
  field :_id, type: String, default: -> { id }
  field :org_id, type: Integer
  field :name, type: String
  field :cmdb, type: Hash
end
