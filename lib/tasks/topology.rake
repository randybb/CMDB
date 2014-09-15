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
rescue
  nil
end

def cdp_tree_for(device_id)
  device_cdp_neighbors = cdp_neighbors_for(device_id)
  @visited_ids << device_id.to_s
  @nodes << {id: device_id.to_s}

  tree = []

  device_cdp_neighbors.each do |device|
    neighbor_id = device['device_id'].to_s
    if @visited_ids.include? neighbor_id
      tree << device.merge(device_cdp: nil)
    else
      @visited_ids << neighbor_id.to_s

      neighbor_cdp = cdp_tree_for(neighbor_id)
      tree << device.merge(device_cdp: neighbor_cdp)
      @edges << {src_id: device_id.to_s, dst_id: neighbor_id, src_if: device[:ne_interface], dst_if: device[:interface]}
    end
    tree
  end

  tree
end

def full_cdp_tree_for(device_id)
  @visited_ids = []
  @nodes = []
  @edges = []
  tree = cdp_tree_for(device_id)

  {nodes: @nodes, edges: @edges}
end

namespace :topology do
  desc "show topology"
  task :default => :environment do |task, params|
    device_id = params.extras
    device_id = 3499861

    tree = full_cdp_tree_for device_id

    ap tree
  end
end