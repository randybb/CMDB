class Infra
  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, type: String
end
