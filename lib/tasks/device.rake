@device_ids = [7357596,
               7357598,
               7357600,
               7357602,
               7357605,
               7357606,
               7357609,
               7357610,
               7437051]

def clogin(ip_address, filename)
  `clogin -x ~/.clogin/show #{ip_address} | tee #{filename}`
end

##
# next functions are required for the configuration parser

# TODO: change to the real location
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

def ipv4_a_to_s(array)
  output = ""
  array.each do |line|
    begin
      cidr = NetAddr::CIDR.create "#{line[:address]} #{line[:mask]}"
      output += cidr.to_s + " "
    rescue
      nil
    end
  end unless array.nil?
  return output.strip
end

def get_hostname(stream)
  /.*\n([\w-]+)[>#]\n.*/.match(stream)[1]
end

def get_commands(stream)
  hostname = get_hostname(stream)
  sections = []
  stream.each_line do |line|
    section = /^#{hostname}[>#]([\w |]+)$/m.match(line)
    sections.push section[1] if section
  end
  sections
end

def get_command_output(stream, cmd)
  cmd_output = ''
  is_cmd_output = false
  hostname = get_hostname(stream)

  stream.each_line do |line|
    is_cmd_output = false if (/^#{hostname}[>#][\w |]+$/m =~ line) == 0
    cmd_output += line if is_cmd_output
    is_cmd_output = true if (/^#{hostname}[>#]#{cmd}$/m =~ line) == 0
  end
  cmd_output
end

def parse_cdp(stream)
  neighbors = []
  neighbor = {}
  stream.each_line do |line|
    if /^-------------------------$/.match(line)
      neighbors.push neighbor unless neighbor.empty?
      neighbor = {}
    end
    match_hostname = /^Device ID: (.*)$/.match(line)
    neighbor[:hostname] = match_hostname[1].strip if match_hostname

    match_plat_cap = /^Platform: (?<platform>.*),  Capabilities: (?<capabilities>.*)$/m.match(line)
    if match_plat_cap
      neighbor[:platform] = match_plat_cap[:platform].strip
      neighbor[:capabilities] = match_plat_cap[:capabilities].strip
    end

    match_ifs = /^Interface: (?<interface>.*),  Port ID \(outgoing port\): (?<ne_interface>.*)$/m.match(line)
    if match_ifs
      neighbor[:interface] = match_ifs[:interface].strip
      neighbor[:ne_interface] = match_ifs[:ne_interface].strip
    end

    match_holdtime = /^Holdtime : (.*)$/m.match(line)
    neighbor[:holdtime] = match_holdtime[1].strip if match_holdtime

    #Version :
    #    Cisco IOS Software, Catalyst 4500 L3 Switch Software (cat4500e-IPBASEK9-M), Version 12.2(53)SG2, RELEASE SOFTWARE (fc1)
    #Technical Support: http://www.cisco.com/techsupport
    #Copyright (c) 1986-2010 by Cisco Systems, Inc.
    #    Compiled Tue 16-Mar-10 03:16 by prod_rel_team
    #
    match_cdp_version = /^advertisement version: (.*)$/.match(line)
    neighbor[:cdp_version] = match_cdp_version[1] if match_cdp_version

    match_vtp_domain = /^VTP Management Domain: (.*)$/.match(line)
    neighbor[:vtp_domain] = match_vtp_domain[1] if match_vtp_domain

    match_native_vlan = /^Native VLAN: (.*)$/.match(line)
    neighbor[:native_vlan] = match_native_vlan[1] if match_native_vlan

    match_duplex = /^Duplex: (.*)$/.match(line)
    neighbor[:duplex] = match_duplex[1] if match_duplex

    neighbor[:mgmt_address] = [] if neighbor[:mgmt_address].nil?
    match_ip_address = /^\s+IP address: (.*)$/.match(line)
    neighbor[:mgmt_address].push match_ip_address[1] if match_ip_address
    neighbor[:mgmt_address].uniq!

    #Power drawn: 15.400 Watts
    #Power request id: 36674, Power management id: 6
    #Power request levels are:15400 13000 0 0 0
  end
  neighbors.push neighbor
  neighbors
end

def parse_interfaces(stream)
  interfaces = []
  interface = {}
  stream.each_line do |line|
    match_ifname = /^interface (.*)$/.match(line)
    interface[:name] = match_ifname[1] if match_ifname

    match_desc = /^ description (.*)$/m.match(line)
    interface[:desc] = match_desc[1].strip if match_desc

    match_sw_mode = /^ switchport mode (.*)$/m.match(line)
    interface[:mode] = match_sw_mode[1].strip if match_sw_mode

    match_sw_access = /^ switchport access vlan (.*)$/m.match(line)
    interface[:access_vlan] = match_sw_access[1].strip if match_sw_access

    match_sw_voice = /^ switchport voice vlan (.*)$/m.match(line)
    interface[:voice_vlan] = match_sw_voice[1].strip if match_sw_voice

    match_sw_trunk_native = /^ switchport trunk native vlan (.*)$/m.match(line)
    interface[:trunk_native_vlan] = match_sw_trunk_native[1].strip if match_sw_trunk_native

    match_sw_trunk_allowed = /^ switchport trunk allowed vlan (.*)$/m.match(line)
    interface[:trunk_allowed_vlan] = match_sw_trunk_allowed[1].strip if match_sw_trunk_allowed

    match_port_channel = /^ channel-group (?<number>[\d]+)( mode (?<mode>.*))$/m.match(line)
    interface[:port_channel] = 'Port-channel' + match_port_channel[:number].strip if match_port_channel

    match_ipv4_address = /^ ip address (?<ip>[\d]{,3}\.[\d]{,3}\.[\d]{,3}\.[\d]{,3}) (?<mask>[\d]{,3}\.[\d]{,3}\.[\d]{,3}\.[\d]{,3})(?<sec> secondary)?$/m.match(line)
    if match_ipv4_address
      interface[:ipv4] = [] if interface[:ipv4].nil?
      primary_addr = match_ipv4_address[:sec].nil? ? true : false
      ipv4_address = {address: match_ipv4_address[:ip].strip, mask: match_ipv4_address[:mask].strip, primary: primary_addr}
      interface[:ipv4].push ipv4_address
    end

    match_schut = /^ shutdown$/.match(line)
    interface[:shutdown] = true if match_schut

    match_poe = /^ power inline never$/.match(line)
    interface[:poe] = false if match_poe

    if /^!$/.match(line)
      interfaces.push interface unless interface.empty?
      interface = {}
    end
  end
  interfaces
end

def parse_version(stream)
  platform = nil
  stream.each_line do |line|
    match_platform = /^(cisco [\w-]+) .*$/.match(line)
    platform = match_platform[1] if match_platform
  end
  platform
end

##
# for graph creation
# http://docs.yworks.com/yfiles/doc/developers-guide/gml.html
def create_gml(nodes, edges)
  output = ""
  output << %q~
graph [
  hierarchic 0
  directed  0
~

  nodes.each_with_index do |node, id|
    output << %Q~  node [
    id #{id.to_s}
    graphics [
      image "#{node[:icon]}"
    ]
    LabelGraphics [
      anchor "s"
      text  "#{node[:hostname]}\n#{node[:ip_addr]}"
    ]
  ]
~
  end

  edges.each do |edge|
    output << %Q~  edge [
    source #{edge[:source].to_s}
    target #{edge[:target].to_s}
    graphics [
      sourceArrow "none"
      targetArrow "none"
    ]
    LabelGraphics [
      text  "#{edge[:source_label]}"
      configuration "AutoFlippingLabel"
      model "six_pos"
      position  "shead"
    ]
    LabelGraphics [
      text  "#{edge[:target_label]}"
      configuration "AutoFlippingLabel"
      model "six_pos"
      position  "thead"
    ]
  ]
~
  end
  output << "]"
end

def create_dot(nodes, edges)
  output = ""
  output << %q~
graph G {
#rankdir=LR
~

  nodes.each do |node|
    output << "\"#{node[:hostname]}\" [labelloc=\"b\", label=\"#{node[:hostname]}\\n#{node[:model]}\", shape=none, image=\"#{node[:icon]}\"]\n"
  end

  edges.each do |edge|
    output << "  \"#{edge[:source]}\" -- \"#{edge[:target]}\" [taillabel=\"#{edge[:source_label]}\", headlabel=\"#{edge[:target_label]}\"]\n"
  end
  output << "}"
end

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

namespace :device do
  task :get_configuration => :environment do
    puts "== Downloading configurations"
    @device_ids.each do |device_id|
      device = CouchPotato.database.load(device_id.to_s)

      puts "= #{device.name} (#{device.id})"
      if device.cmdb[:up] == 0
        created_at = DateTime.now.utc.to_s
        temp_file = "tmp/#{device[:name]}.txt"

        device.timestamps = {} if device.timestamps.nil?

        clogin(device.cmdb[:real_ip], temp_file)

        device_configuration = File.read(temp_file)
        device._attachments = {configuration: {data: device_configuration, content_type: 'text/plain'}}

        device.timestamps[:configuration] = created_at
        device.is_dirty
        CouchPotato.database.save_document device
        puts "OK"
        # File.delete temp_file
      else
        puts "is a slave device for #{device.cmdb[:up_value]}!"
      end
    end
  end

  task :parse_configuration => :environment do
    puts "== Parsing configurations"
    @device_ids.each do |device_id|
      device = CouchPotato.database.load(device_id.to_s)

      puts "= #{device.name} (#{device.id})"
      if device.cmdb[:up] == 0 && device._attachments? && !device._attachments["configuration"].nil?
        created_at = DateTime.now.utc.to_s

        device.device = {} if device.device.nil?
        device.device[:neighbors] = {} if device.device[:neighbors].nil?
        device.timestamps = {} if device.timestamps.nil?

        device_configuration = CouchPotato.couchrest_database.fetch_attachment(device, "configuration").gsub!(/(\r|\n)+/, "\n")

        parsed_hostname = get_hostname(device_configuration)
        parsed_interfaces = parse_interfaces(get_command_output(device_configuration, "show configuration"))
        parsed_cdp = parse_cdp(get_command_output(device_configuration, "show cdp neighbors detail"))

        device.device[:hostname] = parsed_hostname
        device.device[:interfaces] = parsed_interfaces
        device.device[:neighbors][:cdp] = parsed_cdp
        device.timestamps[:parsed_configuration] = created_at
        CouchPotato.database.save_document device
        puts "OK"
      else
        puts "is a slave device for #{device.cmdb[:up_value]}!" if device.cmdb[:up] > 0
        puts "it doesn't contains the configuration attachment!" if device._attachments["configuration"].nil
      end
    end
  end
end
