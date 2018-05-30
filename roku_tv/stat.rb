require "rest-client"
require "json"
require "influxdb"
require "active_support"
require_relative './secrets.rb'

class CollectStat
  def main
    begin
      base_uri = ENV['tv_base_uri']
      device_info = get_req("#{base_uri}/query/device-info")
      device_apps = get_req("#{base_uri}/query/apps")
      active_app = get_req("#{base_uri}/query/active-app")
      #device_info['device_info']['language']
    end
  end

  def get_req(uri)

    response = RestClient::Request.execute(
      method: 'GET',
      url: uri,
    )
    response = JSON.parse(Hash.from_xml(response.body).to_json)
    response
  end

  def connect_db (db)
    influxdb = InfluxDB::Client.new db
    return influxdb
  rescue
    return nil
  end

  def collect_stats()
   stats = {
    "mode" => thermostat.system_mode,
    "temp" => thermostat.temperature,
    "set_temp" => thermostat.system_temperature,
    "humidity" => thermostat.humidity,
    "system_enabled" => thermostat.system_on?.to_s,
    "fan_enabled" => thermostat.system_fan_on?.to_s,
    "System_running" => thermostat.system_active?.to_s,
    "runtime" => stat_time
    }
    stats
  end

  def send_stats(stats,db)
    name = 'RokuTv'

    stats.each do |key,value|
      data = {values: { "#{key}": value },tags:{ location: "LivingRoom" }}
      db.write_point(name, data)
#      puts data
    end
  end

end

CollectStat.new.main
