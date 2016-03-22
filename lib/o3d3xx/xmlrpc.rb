# The module provides a transparent XML-RPC proxy for access to the O3D3XX
# class of devices.
# To get an rough overview of the API connect to the device using your preferred
# Web-Browser: http://192.168.0.69/api/rpc/v1/com.ifm.efector/
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


require 'o3d3xx/xml_rpc_base'

module O3D3XX

  # This class encapsulates the XML-RPC network configuration settings
  class NetworkProxy < XmlRPCBase
    def initialize(proxy)
      config = proxy.getConfig()
      path = "com.ifm.efector/session_#{proxy.getSessionID()}/edit/device/network/"
      super(:host => config[:host], :port => config[:port], :path => path)
    end
  end

  module Application
    TriggerMode = {
      :FREE_RUN       =>  1,
      :PCIC           =>  2,
      :POSITIVE_EDGE  =>  3,
      :NEGATIVE_EDGE  =>  4,
      :BOTH_EDGE      =>  5,
    }
  end

  # This class encapsulates the XML-RPC imager access
  class ImagerProxy < XmlRPCBase
    def initialize(proxy)
      config = proxy.getConfig()
      path = "com.ifm.efector/session_#{proxy.getSessionID()}/edit/application/imager_001" # On O3D3xx only imager_001 is available
      super(:host => config[:host], :port => config[:port], :path => path)
    end
  end


  # This class encapsulates the XML-RPC application access
  class ApplicationProxy < XmlRPCBase
    def initialize(proxy)
      config = proxy.getConfig()
      path = "com.ifm.efector/session_#{proxy.getSessionID()}/edit/application/"
      super(:host => config[:host], :port => config[:port], :path => path)
      @img_proxy = O3D3xx::ImagerProxy.new(proxy)
    end

    def getImagerProxy()
      @img_proxy
    end

  end

  # This class encapsulates the XML-RPC device access
  class DeviceProxy < XmlRPCBase
    def initialize(proxy)
      config = proxy.getConfig()
      path = "com.ifm.efector/session_#{proxy.getSessionID()}/edit/device/"
      super(:host => config[:host], :port => config[:port], :path => path)
      @net_proxy = O3D3xx::NetworkProxy.new(proxy)
    end

    def getNetworkProxy()
      @net_proxy
    end
  end

  # This class encapsulates the XML-RPC Edit-Mode access
  class EditProxy < XmlRPCBase
    def initialize(proxy)
      config = proxy.getConfig()
      path = "com.ifm.efector/session_#{proxy.getSessionID()}/edit/"
      super(:host => config[:host], :port => config[:port], :path => path)
      @proxy = proxy
      @device = O3D3xx::DeviceProxy.new(@proxy)
      @application = nil
    end

    def getApplicationProxy(index)
      self.editApplication(index)
      @application = O3D3xx::ApplicationProxy.new(@proxy)
    end

    def closeApplication()
      self.stopEditingApplication() unless @application == nil
      @application = nil
    end

    def getDeviceProxy()
      @device
    end
  end

  module Session
    OperationMode = {
      :RUN   =>   0,
      :EDIT  =>   1,
    }
  end


  # This class encapsulates the XML-RPC session access
  class SessionProxy  < XmlRPCBase
    def initialize(proxy)
      config = proxy.getConfig()
      path = "com.ifm.efector/session_#{proxy.getSessionID()}/"
      super(:host => config[:host], :port => config[:port], :path => path)
      @edit = nil
      @proxy = proxy
    end

    def getEditObjectProxy()
      if nil == @edit
        self.setOperatingMode(O3D3xx::Session::OperationMode[:EDIT])
        @edit = O3D3xx::EditProxy.new(@proxy)
      end
      @edit
    end
    def closeEdit()
      self.setOperatingMode(O3D3xx::Session::OperationMode[:RUN]) unless @edit == nil
      @edit = nil
    end
  end

  # This class encapsulates the XML-RPC general o3d3xx access
  class O3D3xxProxy < XmlRPCBase

    def initialize(host='192.168.0.69', port=80)
      super(:host => host, :port => port, :path => 'com.ifm.efector/')
      @session = nil
    end

    def getSessionProxy(*args)
      @session_id = requestSession(*args)
      @session = O3D3xx::SessionProxy.new(self)
    end
    def closeSession()
      @session_id = nil
      @session.cancelSession() unless @session == nil
      @session = nil
    end

    def getSessionID
      return @session_id
    end
  end
end
