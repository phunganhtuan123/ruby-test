class Hash
  def symbolize_keys
    JSON.parse(self.to_json, symbolize_names: true)
  end
end
