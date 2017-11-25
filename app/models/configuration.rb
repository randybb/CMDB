class Configuration
  include Mongoid::Document
  include Mongoid::Timestamps

  field :infra_id, type: Integer
  field :file, type: BSON::Code

  belongs_to :equipment
end
