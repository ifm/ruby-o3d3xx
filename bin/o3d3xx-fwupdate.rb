#!/usr/bin/env ruby
# Author::    Christian Ege  (mailto:k4230r6@gmail.com)
# Copyright:: Copyright (c) 2014 - 2016
# License::   MIT
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


require 'timeout'
require 'optparse'
require 'o3d3xx'


def usage(opts)
  puts opts
end


# Check sanity of given options
def check_options(opts, optparse)
  rv = false
  loop do
    if (! opts[:ip_addr])
      usage(optparse)
      puts 'Required argument(s) -I/--ip-addr missing !'
      break
    end

    if ((opts[:ip_addr]) && (! (opts[:start_productive] || opts[:file] || opts[:reboot])))
      usage(optparse)
      puts 'You have to specify at least one of -p/-f/-r!'
      break
    end

    if (((opts[:start_productive]) && (opts[:file] || opts[:reboot]) ))
      usage(optparse)
      puts 'Options -p and -r/-f don\'t fit together'
      break
    end

    rv = true
    break
  end
  rv
end

options = {}
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  options[:file] = nil
  opts.on( '-f', '--file SWU-IMG', 'Image file to upload' ) do |file|
    options[:file] = file
  end
  options[:reboot] = false
  opts.on( '-r', '--reboot', 'Force reboot to productive mode after all other action' ) do
    options[:reboot] = true
  end

  options[:ip_addr] = nil
  opts.on( '-I', '--ip-addr IP-ADDR', 'Set TCP/IP address of target' ) do |ip_addr|
    options[:ip_addr] = ip_addr
  end

  options[:start_productive] = false
    opts.on( '-p', '--start-productive', 'Start productive system only without uploading file' ) do
      options[:start_productive] = true
  end

  opts.on( '-h', '--help', 'Display this help message' ) do
    usage(opts)
    exit 0
  end
end

optparse.parse!(ARGV)

exit(1) unless check_options(options, optparse)

ip_addr = options[:ip_addr] || ENV['IP_ADDR'] || raise('Error: no ip address given!')

swupdate_settings = {
  :host => ip_addr,
  :port => 8080,
  :ssh_ident => options[:identity]
}

swupdate = O3D3XX::Swupdate.new(swupdate_settings)

rv = 0

if options[:file]
  if swupdate.read_status_empty()
    print "Uploading swu image #{options[:file]} ..."
    swupdate.upload_file(options[:file])
    if swupdate.wait_for_status(O3D3XX::Swupdate::UPLOAD_SUCCESS, 60)
      puts ' OK'
      rv = 0
    else
      puts ' FAILED!'
      rv = 1
    end
  else
    puts 'Status of http server could not settle!?'
  end
end

if (options[:start_productive] || options[:reboot]) && (rv == 0)
  print 'Starting productive mode ...'
  if swupdate.restart_device()
      puts ' OK'
      rv = 0
  else
    puts ' FAILED!'
  end
end

exit(rv)
# EOF
