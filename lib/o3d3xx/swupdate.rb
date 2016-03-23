
# The module provides access to the swupdate process
#
# swupdate - Software Update for Embedded Systems provides a web ui to upload
# an installation file to an embedded target. This can also be used for an automated
# installation process.
#
#
# For manual access an web ui is provided
# Web-Browser: http://<ip of the device>:8080
#
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
require 'uri'
require 'net/http'
require 'json'

module O3D3XX

  class Swupdate
    UPLOAD_SUCCESS={"Status"=>"3", "Msg"=>"SWUPDATE successful !", "Error"=>"0"}

    def initialize (settings={})
      raise 'No host name given !' if settings[:host].nil?
      @config = {
        :host => settings[:host],
      }
      if settings[:port].nil?
        @config[:port] = 8080
      else
        @config[:port] = settings[:port]
      end
      @base_uri = "http://#{@config[:host]}:#{@config[:port]}"
    end

    # Print out an error message when an error was raised
    def not_in_swupdate?()
      puts 'FAILED'
      puts 'Device not in SWUPDATE mode?'
    end
    # Uploads a file to swupdate system. So far this file has
    # to be a swu image file.
    # This call is asynchronous to the following installation
    # procedure, i.e. one has to poll for installation finish
    # via query_status()
    #
    # @param filename   filename of swu image to install on target
    #
    def upload_file(filename)
      res = false
      raise 'Invalid file name given !' unless File.exist?(filename)
      uri = URI.parse("#{@base_uri}/handle_post_request")
      http = Net::HTTP.new(uri.host, uri.port)
      header = {
        'Content-Type'=> 'application/octet-stream',
        'X_FILENAME'=> "#{File.basename(filename)}",
      }
      request = Net::HTTP::Post.new(uri.request_uri,header)
      request.body = File.read(filename)
      begin
        http.request(request) { |response|
          break
        }
        res = true
      rescue Errno::ECONNRESET
        not_in_swupdate?
      rescue Errno::ECONNREFUSED
        not_in_swupdate?
      end

      res
    end

    # Reads status queue empty on http server, i.e.
    # will return status from server until two consecutive
    # status values are identical.
    #
    # @param timeout    Time to wait for http server to settle
    #
    def read_status_empty(timeout = 5)
      rv = false
      Timeout::timeout(timeout) do
        loop do
          rv1 = query_status
          rv2 = query_status
          break if rv1 == rv2
        end
        rv = true
      end
      rv
    end

    # Query status from http server
    #
    # @return json representation of http status
    #         e.g. {"Status"=>"0", "Msg"=>"", "Error"=>"0"}
    #
    def query_status()
      rv = ''
      uri = URI.parse("#{@base_uri}/getstatus.json")
      begin
        response = Net::HTTP.get_response(uri)
        rv = JSON.parse(response.body)
        #Net::HTTP.get_print(uri)
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
          Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      end
      #puts rv
      rv
    end

    # Waits for specific status of http server with max. timeout
    #
    # @param status_hash    Hash of status values, e.g.
    #                       {"Status"=>"0", "Msg"=>"", "Error"=>"0"}
    #
    # @param timeout        Time in seconds to wait for given status to be returned
    #                       from http server
    #
    def wait_for_status(status_hash, timeout)
      rv = false
      Timeout::timeout(timeout) do
        loop do
          rv1 = query_status
          break if rv1 == status_hash
          # Print error messages
          if rv1['Status'] && (rv1['Status'] == '4')
            puts rv1['Msg'] if rv1['Msg']
          end
          sleep 1
        end
        rv = true
      end
      rv
    end


    # Restarts device
    def restart_device()
      uri = URI.parse("#{@base_uri}/reboot_to_live")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Connection'] = 'keep-alive'
      http.request(request)
    end

  end
end
