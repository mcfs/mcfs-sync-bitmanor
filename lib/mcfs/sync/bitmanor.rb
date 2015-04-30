
require 'yaml'
require 'logger'
require 'commander'
require 'net/http'

require_relative 'bitmanor/version'

module McFS; module Sync
  
  class BitManorApp
    Log = Logger.new(STDOUT)
  
    include Commander::Methods
    
    DEFAULT_MASTER_IP = 'www.bitmanor.net'
    DEFAULT_MASTER_PORT = 443
    
    DEFAULT_RUNFILE = ENV['HOME'] + "/.mcfs/mcfs-service.run"
    
    def initialize
      program :name, 'McFS BitManor Synchronizer'
      program :version, McFS::Sync::BitManor::VERSION
      program :description, 'Multi-cloud file system synchronizer for bitmanor.net'

      command :sync do |cmd|
        cmd.syntax = File.basename($0) + ' sync <user> [options]'
        cmd.description = 'description for sync command'
        
        cmd.option '-H', '--master IP', String, "IP address of master (default: #{DEFAULT_MASTER_IP})"
        cmd.option '-P', '--mport PORT', Integer, "Port number of master (default: #{DEFAULT_MASTER_PORT})"
        
        cmd.option '-R', '--runfile PATH', String, "Runtime (local) file of slave (default: #{DEFAULT_RUNFILE})"
  
        cmd.action do |args, options|
          options.default master:  DEFAULT_MASTER_IP
          options.default mport:   DEFAULT_MASTER_PORT
          options.default runfile: DEFAULT_RUNFILE
          
          sync(args, options)
        end # action
      end # :sync

    end # initialize
    
    private
    
    def sync(args, options)
      master_ip = options.master
      master_port = options.mport
      
      runtime_config = YAML.load_file(options.runfile)
      
      slave_ip = runtime_config['ip']
      slave_port = runtime_config['port']
      slave_secret = runtime_config['secret']
      
      updates_request = {
        'lastid' => nil
      }
      
      loop do
        update_data = Net::HTTP.new(master_ip, master_port).post('/config/updates', updates_request.to_yaml).body
        
        update = YAML.load(update_data)
        
        if update
          Log.info "Update for #{update['path']}"
          
          puts update_data
        
          # FIXME: need to check the status of update operation
          Net::HTTP::new(slave_ip, slave_port).post('/' + update['path'], update['cmd'].to_yaml)
          
          updates_request['lastid'] = update['id']
          next
        end
        
        sleep 5
      end
    end # sync
    
  end # class BitManorApp
  
end; end
