class CMDB
  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, type: String
  field :timestamps, type: Hash
end
