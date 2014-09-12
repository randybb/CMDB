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

=begin
  view :all, key: :name, :conditions => 'doc.cmdb'
  view :wlc, key: :name, :conditions => 'doc.cmdb.type == "Wireless Controller"'
  view :test, key: :created_at, :conditions => 'doc.cmdb.type == "Wireless Controller"'
  view(:for_sitid,
       :map => %q{
function(doc){
  if(doc.ruby_class && doc.ruby_class == 'Equipment') {
    emit(doc.cmdb.sitid, null);
  }
}
  },
       :include_docs => true, :type => :custom)
  view(:find_by_alias,
       :map => %q{
function(doc){
  if(doc.ruby_class && doc.ruby_class == 'Equipment') {
    if(!doc.cmdb.alias_equipment || doc.cmdb.alias_equipment == "" || doc.cmdb.alias_equipment == "none"){
      var hostname = doc.name.replace(".lan.skf.net","").toLowerCase();
    } else {
      var hostname = doc.cmdb.alias_equipment.toLowerCase();
    }
    emit(hostname, null);
  }
}
  },
       :include_docs => true, :type => :custom)
=end
end