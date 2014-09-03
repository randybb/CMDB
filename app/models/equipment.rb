class Equipment
  include CouchPotato::Persistence
  property :_id
  property :orgid
  property :name
  property :_attachments
  property :timestamps
  property :device
  property :cmdb

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
end
