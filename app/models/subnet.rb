class Subnet
  include CouchPotato::Persistence
  property :_id
  property :orgid
  property :name
  property :cmdb

  view :all, key: :name, :conditions => 'doc.cmdb'
end
