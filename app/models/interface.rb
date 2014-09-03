class Interface
  include Mongoid::Document
  include Mongoid::Timestamps

  field :infrid, type: Integer
  field :_id, type: String, default: -> { infrid }
  field :orgid, type: Integer
  field :name, type: String
  field :cmdb, type: Hash
end
