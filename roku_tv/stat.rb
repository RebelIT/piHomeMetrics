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
      db_connect = connect_db(ENV['db'])

      unless device_info.nil? || db_connect.nil?
        roku_tv_stats = collect_stats(device_info)

        unless roku_tv_stats.nil?
            send_stats(roku_tv_stats,db_connect)
        end
      end
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

  def collect_stats(device_info)
   stats = {
    "name" => device_info['device_info']['user-device-name'],
    "version" => device_info['device_info']['software-version'],
    "build" => device_info['device_info']['software-build'],
    "state" => device_info['device_info']['power-mode']
    }
    stats
  end

  def send_stats(stats,db)
    name = 'RokuTv'

    stats.each do |key,value|
      data = {values: { "#{key}": value },tags:{ location: "FamilyRoom" }}
#      db.write_point(name, data)
     puts data
    end
  end

end

CollectStat.new.main
