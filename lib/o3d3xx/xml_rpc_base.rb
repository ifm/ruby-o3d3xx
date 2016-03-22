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


require 'xmlrpc/client'
require 'timeout'

class XmlRPCBase

  attr_reader :rpc_cl

  # Initializes XMLRPC connection. Needs connection and
  # Request parameters via given settings hash
  #
  # @param settings   hash of settings: :host, :port, :path
  #
  def initialize(settings={})
    raise 'No host name given !' if settings[:host].nil?
    raise 'No port given !' if settings[:port].nil?
    raise 'No endpoint given !' if settings[:path].nil?
    @config = {
      :host => settings[:host],
      :port => settings[:port],
      :path => '/api/rpc/v1/' + settings[:path]
    }

    @rpc_cl = XMLRPC::Client.new(@config[:host],
                                 @config[:path],
                                 @config[:port], nil, nil,
                                 nil, nil, nil, 20)   # 20 seconds connection timeout
    #dump
  end


  # Calls any method via xmlrpc
  def method_missing(meth, *args)
    arg = args
    begin
      @rpc_cl.call_async(meth.to_s, *arg)
    rescue XMLRPC::FaultException => e
      if e.message.include? 'method not found'
        super
      else
        raise
      end
    end
  end


  # Returns configuration object
  def getConfig
    return @config
  end


  # Dumps configuration
  def dump
    puts "Host: #{@config[:host]}"
    puts "Port: #{@config[:port]}"
    puts "URL : #{@config[:path]}"
  end
end
