Moped::BSON = BSON

SERVER_IMG_PATH = "http://localhost:3000/images/"
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
    unknown: 'cisco_shapes/unknown.png',
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
    when /^cisco AIR-CAP.*$/
      model = /^cisco AIR-(.*)$/.match(string)[1]
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
      return {class: "unknown", model: string, icon: ICON[:unknown]}
  end
end

# TODO: interface => src_interface, ne_interface => interface
def cdp_neighbors_for(device_id)
  device = Equipment.where(id: device_id).first

  src_device_name = device.alias
  device_cdp = device.device[:neighbors][:cdp]
  device_cdp_with_id = []

  device_cdp.each do |device|
    device_name = device[:hostname].downcase
    device_class = classify_node device[:platform]
    infr = Equipment.where(alias: device_name)
    infrid = ''
    infrid = infr.first[:id] unless infr.nil? || infr.first.nil?
    device_cdp_with_id << device.merge(device_name: device_name, device_id: infrid, device_class: device_class, src_device_name: src_device_name, src_device_id: device_id.to_s)
  end

  device_cdp_with_id
rescue
  nil
end

def cdp_tree_for(device_id)
  device_cdp_neighbors = cdp_neighbors_for(device_id)
  device = Equipment.where(id: device_id).first
  unless device.nil?
    @visited_ids << device_id.to_s

    tree = []
    unless device_cdp_neighbors.nil?
      device_cdp_neighbors.each do |device|
        neighbor_id = device[:device_id].to_s

        if @visited_ids.include? neighbor_id
          tree << device.merge(device_cdp: nil)
        else
          @visited_ids << neighbor_id.to_s
          neighbor_cdp = cdp_tree_for(neighbor_id)
          tree << device.merge(device_cdp: neighbor_cdp)
        end

        @edges << device
        tree
      end
    end
  end

  tree
end

def full_cdp_tree_for(device_id)
  @visited_ids = []
  nodes = []
  @edges = []

  tree = cdp_tree_for(device_id)

  @edges.each do |edge|
    nodes << {id: edge[:device_id], name: edge[:device_name], class: edge[:device_class], mgmt_address: edge[:mgmt_address]}
  end
  nodes.uniq!

  # add IDs for not defined devices in CMDB
  nodes.map! do |node|
    if node[:id].empty?
      node.merge!({id: Random.rand(100).to_s})
    else
      node
    end
  end

  @edges.map! do |edge|
    if edge[:device_id].empty?
      node = nodes.find { |node| node[:name] == edge[:device_name] }
      edge.merge!({device_id: node[:id]})
    else
      edge
    end
  end

  {nodes: nodes, edges: @edges}
end

# http://docs.yworks.com/yfiles/doc/developers-guide/gml.html
def create_gml(nodes, edges)
  output = ''
  output << %q~
graph [
  hierarchic 0
  directed  0
~

  nodes.each do |node|
    output << %Q~  node [
    id #{node[:id]}
    graphics [
      image "#{SERVER_IMG_PATH}#{node[:class][:icon]}"
    ]
    LabelGraphics [
      anchor "s"
      text  "#{node[:name]}\n#{node[:mgmt_address].first}"
    ]
  ]
~
  end

  edges.each do |edge|
    output << %Q~  edge [
    source #{edge[:src_device_id]}
    target #{edge[:device_id]}
    graphics [
      sourceArrow "none"
      targetArrow "none"
      width 2
    ]
    LabelGraphics [
      text  "#{edge[:interface]}"
      configuration "AutoFlippingLabel"
      model "six_pos"
      position  "shead"
    ]
    LabelGraphics [
      text  "#{edge[:ne_interface]}"
      configuration "AutoFlippingLabel"
      model "six_pos"
      position  "thead"
    ]
  ]
~
  end
  output << ']'
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
    `open #{gml_filename}`
  end
end