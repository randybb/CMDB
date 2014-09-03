CMDB_WEB = YAML.load_file(Rails.root.to_s + '/config/cmdb.yml')[Rails.env].to_hash.symbolize_keys

