require 'moped'
require 'bson'
Moped::BSON = BSON

SERVER_IMG_PATH = "http://localhost:3000/public/images/"
ICON = {
    firewall_asa: 'cisco_shapes/firewall_asa.png',
    firewall: 'cisco_shapes/firewall.png',
    router_fw: 'cisco_shapes/router_fw.png',
    router: 'cisco_shapes/router.png',
    router_switch_fwsm: 'cisco_shapes/router_switch_fwsm.png',
    router_switch: 'cisco_shapes/router_switch.png',
    router_switch_vss: 'cisco_shapes/router_switch_vss.png',
    switch_dc: 'cisco_shapes/switch_dc.png',
    switch_l2: 'cisco_shapes/switch_l2.png',
    switch_l2_stack: 'cisco_shapes/switch_l2_stack.png',
    switch_l3: 'cisco_shapes/switch_l3.png',
    switch_l3_stack: 'cisco_shapes/switch_l3_stack.png',
    wlan_ap_dual: 'cisco_shapes/wlan_ap_dual.png',
    wlan_ap_lwap: 'cisco_shapes/wlan_ap_lwap.png',
    wlan_ap: 'cisco_shapes/wlan_ap.png',
    wlan_controller: 'cisco_shapes/wlan_controller.png',
}

def abbr_ifs(string)
  replacement_strings = [
      %w(FastEthernet Fa),
      %w(GigabitEthernet Gi),
      %w(TenGigabitEthernet Te),
      %w(Port-channel Po),
      %w(Vlan Vl),
      %w(LAGInterface LAG)
  ]
  replacement_strings.each do |from, to|
    string.gsub!(from, to)
  end
  string
end

def classify_node(string)
  case string
    when /^AIR-CAP.*$/
      model = /^AIR-(.*)$/.match(string)[1]
      return {class: 'wlan_ap', model: model, icon: ICON[:wlan_ap]}
    when /^AIR-(WLC|CT).*$/
      model = /^AIR-(.*)$/.match(string)[1]
      return {class: 'wlan_controller', model: model, icon: ICON[:wlan_controller]}
    when /^cisco WS-C2.*$/
      model = /^cisco WS-(.*)$/.match(string)[1]
      return {class: 'switch_l2', model: model, icon: ICON[:switch_l2]}
    when /^cisco WS-C3.*$/
      model = /^cisco WS-(.*)$/.match(string)[1]
      return {class: 'switch_l3', model: model, icon: ICON[:switch_l3]}
    when /^cisco WS-C[46].*$/
      model = /^cisco WS-(.*)$/.match(string)[1]
      return {class: 'router_switch', model: model, icon: ICON[:router_switch]}
    when /^Cisco 72.*$/
      model = /^(.*)$/.match(string)[1]
      return {class: 'router', model: model, icon: ICON[:router]}
    else
      return {class: "unknown", model: string, icon: ''}
  end
end

def cdp_neighbors_for(device_id)
  device = Equipment.where(id: device_id).first

  src_device_name = device.alias
  device_cdp = device.device[:neighbors][:cdp]
  device_cdp_with_id = []

  device_cdp.each do |device|
    device_name = device[:hostname].downcase
    infr = Equipment.where(alias: device_name)
    infrid = ''
    infrid = infr.first[:id] unless infr.nil? || infr.first.nil?
    device_cdp_with_id << device.merge(device_name: device_name, device_id: infrid, src_device_name: src_device_name, src_device_id: device_id.to_s)
  end

  device_cdp_with_id
rescue
  nil
end

def cdp_tree_for(device_id)
  device_cdp_neighbors = cdp_neighbors_for(device_id)
  device = Equipment.where(id: device_id).first
  unless device.nil?
    src_device_name = device.alias
    @visited_ids << device_id.to_s
    @nodes << {id: device_id.to_s, name: src_device_name}

    tree = []
    unless device_cdp_neighbors.nil?
      device_cdp_neighbors.each do |device|
        neighbor_id = device[:device_id].to_s
        node = @nodes.find { |node| node[:name] == device[:hostname] }
        neighbor_class = classify_node device[:platform]

        if @visited_ids.include? neighbor_id
          tree << device.merge(device_cdp: nil, device_class: neighbor_class)
        else
          @visited_ids << neighbor_id.to_s

          neighbor_cdp = cdp_tree_for(neighbor_id)
          tree << device.merge(device_cdp: neighbor_cdp, device_class: neighbor_class)
        end

        # TODO: this is a stupid workaround, but it works :( - it will add a random ID for unknown devices
        if neighbor_id.empty?
          if node.nil?
            neighbor_id = Random.rand(100).to_s
            @nodes << {id: neighbor_id, name: device[:hostname]}
          else
            neighbor_id = node[:id]
          end
        end

        @edges << {src_id: device_id.to_s, dst_id: neighbor_id, src_if: abbr_ifs(device[:interface]), dst_if: abbr_ifs(device[:ne_interface])}
        tree
      end
    end
  end

  tree
end

def full_cdp_tree_for(device_id)
  @visited_ids = []
  @nodes = []
  @edges = []
  tree = cdp_tree_for(device_id)

  {nodes: @nodes, edges: @edges.uniq, tree: tree}
end

# http://docs.yworks.com/yfiles/doc/developers-guide/gml.html
def create_gml(nodes, edges)
  output = ""
  output << %q~
graph [
  hierarchic 0
  directed  0
~

  nodes.each do |node|
    output << %Q~  node [
    id #{node[:id]}
    graphics [
      image "#{node[:icon]}"
    ]
    LabelGraphics [
      anchor "s"
      text  "#{node[:name]}"
    ]
  ]
~
  end

  edges.each_with_index do |edge, id|
    output << %Q~  edge [
    source #{edge[:src_id]}
    target #{edge[:dst_id]}
    graphics [
      sourceArrow "none"
      targetArrow "none"
    ]
    LabelGraphics [
      text  "#{edge[:src_if]}"
      configuration "AutoFlippingLabel"
      model "six_pos"
      position  "shead"
    ]
    LabelGraphics [
      text  "#{edge[:dst_if]}"
      configuration "AutoFlippingLabel"
      model "six_pos"
      position  "thead"
    ]
  ]
~
  end
  output << "]"
end

namespace :topology do
  desc "show topology"
  task :default => :environment do |task, params|
    device_id = params.extras
    #device_id = 3499861 # few devices
    device_id = 7357596 # many devices

    full_tree = full_cdp_tree_for device_id

    ap full_tree

    gml_filename = "cdp_topo.gml"
    gml = File.new(gml_filename, "w")
    gml.write create_gml(full_tree[:nodes], full_tree[:edges])
    gml.close
    # `open #{gml_filename}`
  end
end