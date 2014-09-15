require 'moped'
require 'bson'
Moped::BSON = BSON

def cdp_neighbors_for(device_id)
  device = Equipment.where(id: device_id).first

  device_cdp = device.device[:neighbors][:cdp]
  device_cdp_with_id = []

  device_cdp.each do |device|
    device_name = device[:hostname].downcase
    infr = Equipment.where(alias: device_name)
    infrid = ''
    infrid = infr.first[:id] unless infr.nil? || infr.first.nil?
    device_cdp_with_id << device.merge(device_name: device_name, device_id: infrid)
  end

  device_cdp_with_id
end

def cdp_tree_for(device_id)
  tree = []

  device_cdp_neighbors = cdp_neighbors_for(device_id)

  device_cdp_neighbors.each do |device|
    neighbor_id = device['device_id']

    neighbor_cdp = cdp_neighbors_for(neighbor_id)
    tree << device.merge(device_cdp: neighbor_cdp)
  end

  tree
end

namespace :topology do
  desc "show topology"
  task :default => :environment do |task, params|
    device_id = params.extras
    device_id = 3499861

    tree = cdp_neighbors_for device_id

    ap tree
  end
end
