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



require 'socket'
require 'timeout'
require 'logger'

module O3D3XX

  CHUNKTYPE = {
    CT_USERDATA:                  0,
    CT_RADIAL_DISTANCE_IMAGE:   100,
    CT_AMPLITUDE_IMAGE:         103,
    CT_INTENSITY_IMAGE:         102,
    CT_NORM_AMPLITUDE_IMAGE:    101,
    CT_CARTESIAN_X_COMPONENT:   200,
    CT_CARTESIAN_Y_COMPONENT:   201,
    CT_CARTESIAN_Z_COMPONENT:   202,
    CT_CARTESIAN_ALL:           203,
    CT_UNIT_VECTOR_E1:          220,
    CT_UNIT_VECTOR_E2:          221,
    CT_UNIT_VECTOR_E3:          222,
    CT_UNIT_VECTOR_ALL:         223,
    CT_CONFIDENCE_IMAGE:        300,
    CT_RAWDATA:                 301,
    CT_DIAGNOSTIC:              302,
    CT_EXTRINSIC_CALIBRATION:   400,
    CT_JSON_MODEL:              500,
  }

  CHUNKPIXELFORMAT = {
    PF_FORMAT_8U:    0,
    PF_FORMAT_8S:    1,
    PF_FORMAT_16U:   2,
    PF_FORMAT_16S:   3,
    PF_FORMAT_32U:   4,
    PF_FORMAT_32S:   5,
    PF_FORMAT_32F:   6,
    PF_FORMAT_64U:   7,
    PF_FORMAT_64F:   8,
    PF_FORMAT_16U2:  9,
    PF_FORMAT_32F3: 10,
    PF_FORMAT_12U:  11,
  }

  class PCIC
    def initialize()
      @remote = nil
      @protocol = 3
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::WARN
    end
    def connect(host="192.168.0.69",port="50010")
      unless @remote == nil
        disconnect()
      end
      @remote = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
      @protocol = 3
      begin
        timeout(3) do
          @remote.connect(Socket.pack_sockaddr_in(port, host))
        end
      rescue
        @logger.fatal("Unable to connect to tcp://#{host}:#{port}")
        @remote = nil
        return false
      end
      #@protocol = detect_protocol()
      #set_version(3)
    end
    def disconnect()
      @remote.close()
      @remote = nil
    end
    def detect_protocol()
      proto = nil
      begin
        result = nil
        @logger.debug("detect_protocol ")
        begin
          timeout(11) do
            send_v3("V?")
            result = @remote.recvfrom(20)
            @logger.debug("Received: #{result} ")
          end
        rescue Timeout::Error => e
          @logger.fatal("Timeout while receiving data occurred: #{e.message}")
          return
        end
        test = result.join()
        proto = nil
        proto = 1 if test =~ /(\?)|(\d{2} \d{2} \d{2})\r\n/
        proto = 2 if test =~ /\d{4}(\?)|(\d{2} \d{2} \d{2})\r\n/
        proto = 3 if test =~ /\d{4}L\d{9}\r\n\d{4}/
        proto = 4 if test =~ /L\d{9}\r\n(\?)|(\d{2} \d{2} \d{2})\r\n/
        # If the device is in continuous mode and asynchronous messages are enabled
        # we have to pull the complete frame out of the socket. Otherwise every consecutive
        # PCIC call will fail due to the fact that we start in the middle of a frame.
        if(proto == 3 )
          ticket,length = test.match(/(\d{4})L(\d{9})\r\n/i).captures
          timeout(5) do
            # get the rest of the response
            trailer = @remote.read(length.to_i-4)
          end
          # recv_v3 handles asynchronous messages so let it handle them.
          dum = recv_v3() if '0000' == ticket
        end
        raise 'Unable to detect PCIC protocol' if proto == nil
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        raise('Timeout while detecting version')
        proto = nil
      end
      proto
    end
    def set_version(version=3)
      res = transfer("v%02d"%version)
      @protocol = version
      res
    end
    def version()
      return transfer("V?")
    end
    def help()
      transfer("H?")
    end
    def device_info()
      transfer("G?")
    end
    def async_trigger()
      return transfer("t")
    end
    def sync_trigger()
      transfer("T?")
    end

    def get_lastimage(img = 3)
      transfer("I%02d?"%img)
    end


    def async_result(state=false)
      data = "p%d" % [ state ? 1 : 0 ]
      res = true
      transfer(data)
      res
    end
    def transfer(data)
      raise 'Protocol #{@protocol} currently not supported' if @protocol == 1
      raise 'Protocol #{@protocol} currently not supported' if @protocol == 2
      return transfer_v3(data) if @protocol == 3
      raise 'Protocol #{@protocol} currently not supported' if @protocol == 4
    end
    def send_v3(data)
      ticket = "%04d" % [1000+rand(8999)]
      length = "%09d" % [data.bytesize+6]
      sendbuf = "#{ticket}L#{length}\r\n#{ticket}#{data}\r\n"
      @logger.info("Request (#{@protocol}) : %{sendbuf}" % {:sendbuf => escape_pcic_string(sendbuf)})
      timeout(5) do
        @remote.send(sendbuf,0)
      end
    end
    def transfer_v3(data,omit_async=true)
      send_v3(data)
      continue = true
      response = nil
      begin
        async,ticket,response = recv_v3()
        continue = false; continue = true if async and omit_async
      end while continue
      return response
    end

    def recv_v3()
      data = nil
      async = false
      trailer = nil
      # The V3 response shall look like this
      # <4 Byte ticket >L<9 Byte Length in dec>\r\n<4 Byte ticket ><Response>\r\n
      # receive <ticket>L<length>\r\n to check if we in sync and how much
      # data we have to receive in the next step
      timeout(5) do
        data = @remote.read(16)
      end
      @logger.info("Header   : %{res}" % {:res => escape_pcic_string(data)})
      begin
        ticket,length = data.match(/(\d{4})L(\d{9})\r\n/i).captures
      rescue
        @logger.fatal(">>> rescue: #{data} <<<")
      end
      size = length.to_i
      @logger.info("Length   : %d " % size )
      if ticket == "0000"
        @logger.info('ASYNC reply Caught !!!!')
        async = true
      else
        async = false
      end
      timeout(5) do
        trailer = @remote.read(size)
      end
      if size < 80 and trailer.length < 80
        @logger.debug("Trailer  : %{res} <<<<" % {:res => escape_pcic_string(trailer)})
      else
        escaped = escape_pcic_string(trailer)
        @logger.debug("Trailer  : %{start} [...] %{stop}" % {:start => escaped[0..20], :stop => escaped[-20..-1]})
      end
      ticket_trailer = trailer[0..3]
      unless ticket_trailer == ticket
        raise "Ticket mismatch. Header ticket: #{ticket} trailer ticket: #{ticket_trailer}"
      end
      # remove ticket and trailing \r\n
      return async,ticket,trailer[4..-3]
    end

    def escape_pcic_string(data)
      result = ""
      result = data.gsub("\n","\\\\n").gsub("\r","\\\\r") unless data == nil
    end
  end

  # Handle PCIC binary/image chunks
  class Chunk
    def self.parse(data)
      chunk_header =  data.unpack('L<9*')
      result = {
        :CHUNK_TYPE => chunk_header[0],
        :CHUNK_SIZE => chunk_header[1],
        :HEADER_SIZE => chunk_header[2],
        :HEADER_VERSION => chunk_header[3],
        :IMAGE_WIDTH => chunk_header[4],
        :IMAGE_HEIGTH => chunk_header[5],
        :PIXEL_FORMAT => chunk_header[6],
        :TIME_STAMP => chunk_header[7],
        :FRAME_COUNT => chunk_header[8],
        :PIXEL_DATA => data[chunk_header[2]...chunk_header[1]],
      }
    end
    def self.info(chunk)
      info = Array.new
      info.push("CHUNK type        : #{chunk[:CHUNK_TYPE]}")
      info.push("CHUNK size        : #{chunk[:CHUNK_SIZE]}")
      info.push("CHUNK header size : #{chunk[:HEADER_SIZE]}")
      info.push("CHUNK version     : #{chunk[:HEADER_VERSION]}")
      info.push("CHUNK height      : #{chunk[:IMAGE_HEIGTH]}")
      info.push("CHUNK width       : #{chunk[:IMAGE_WIDTH]}")
      info.push("CHUNK format      : #{chunk[:PIXEL_FORMAT]}")
      info.push("CHUNK time stamp  : #{chunk[:TIME_STAMP]}")
      info.push("CHUNK frame count : #{chunk[:FRAME_COUNT]}")
      info.push("CHUNK data size   : #{chunk[:PIXEL_DATA].length}")
    end

    def self.parseChunkArray(data)
      result = Array.new
      offset = 0
      while offset < data.size
        chunk = self.parse(data[offset..data.size])
        result << chunk
        offset += chunk[:CHUNK_SIZE]
      end
      return result
    end

  end
end
