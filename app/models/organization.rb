class Organization
  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, type: Integer
  field :_id, type: String, default: -> { id }
  field :name, type: String
end
