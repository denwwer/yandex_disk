require 'net/http'
require 'uri'
require 'zlib'
require 'base64'
require 'rexml/document'

require 'yandex_disk/cfg'
require 'yandex_disk/ext'
require 'yandex_disk/chunked'

module YandexDisk
  class RequestError < Exception; end

  class Api

    def initialize(login, pwd)
      @token = 'Basic ' + Base64.encode64("#{login}:#{pwd}")
    end

    # TODO gzip file when send
    # fist argument is file name, second is hash with options:
    # chunk_size - file chunk size, default is 100
    def upload(file, path = '', options = {})
      # valid file?
      raise RequestError, "File not found." if file.nil? || !File.file?(file)
      # create path
      create_path(path) if options[:force]
      options[:chunk_size] ||= 100
      @file = File.open(file)
      options[:headers] = {'Expect' => '100-continue',
                           #'Content-Encoding' => 'gzip',
                           'Transfer-Encoding' => 'chunked',
                           'content-type' => 'application/binary'}

      send_request(:put, options.merge({:path => File.join( path, File.basename(file) )}))
      @file.close
      return true
    end

    # download file to local disc
    # arguments: file name, destination path
    def download(file, save_path)
      option = {:path => file,
                :headers => {'TE' => 'chunked',
                             'Accept-Encoding' => 'gzip'}}

      send_request(:get, option)

      data = nil
      # unzip if zipped
      if @response.header['Content-Encoding'] == 'gzip'
        sio = StringIO.new( @response.body )
        gz = Zlib::GzipReader.new( sio )
        data = gz.read
      else
        data = @response.body
      end
      File.open(File.join(save_path, file.split('/').last), 'w'){|f| f.write(data)}

      return true
    end

    # Create directory or force create directory path
    #
    # yd.create_dir(['test'])
    # yd.create_dir(['photos', 'my vacation'])
    def create_path(path)
      c_path = ''
      path.split('/').each do |p|
        next if p.empty?
        c_path << p + '/'
        send_request(:mkcol, {:path => c_path})
      end
    end
    alias_method :mkdir, :create_path

    def size
      body = '<?xml version="1.0" encoding="utf-8"?><D:propfind xmlns:D="DAV:"><D:prop><D:quota-available-bytes/><D:quota-used-bytes/></D:prop></D:propfind>'
      send_propfind(0, {:body => body})
      xml = REXML::Document.new(@response.body)
      prop = 'd:multistatus/d:response/d:propstat/d:prop/'

      return {:available => xml.elements[prop + 'd:quota-available-bytes'].text.to_i,
             :used => xml.elements[prop + 'd:quota-used-bytes'].text.to_i}
    end

    def exist?(path)
      body = '<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><displayname/></prop></propfind>'
      send_propfind(0, {:path => path, :body => body})
      return true
    rescue RequestError
      return false
    end

    def properties(path)
      body = '<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><displayname/><creationdate/><getlastmodified/><getcontenttype/><getcontentlength/><public_url xmlns="urn:yandex:disk:meta"/></prop></propfind>'
      send_propfind(0, {:path => path, :body => body})
      prop = 'd:multistatus/d:response/d:propstat/d:prop/'
      xml = REXML::Document.new(@response.body)
      type = xml.elements[prop + 'd:getcontenttype'].text
      size = xml.elements[prop + 'd:getcontentlength'].text.to_i

      return {:name => xml.elements[prop + 'd:displayname'].text,
              :created => xml.elements[prop + 'd:getlastmodified'].text,
              :updated => xml.elements[prop + 'd:getlastmodified'].text,
              :type => type ? type : 'dir',
              :size => size,
              :is_file => size > 0,
              :public_url => xml.elements[prop + 'public_url'].text}
    end

    def files(path = '', with_root = true)
      send_propfind(1, {:path => path})
      xml = REXML::Document.new(@response.body)
      prop = 'd:propstat/d:prop/'
      files = []
      xml.elements.each('d:multistatus/d:response') do |res|
        name = URI.decode(res.elements[prop + 'd:displayname'].text)
        next if !with_root && path.split('/').last == name
        size = res.elements[prop + 'd:getcontentlength'].text.to_i

        files << {:name => name,
                  :path => URI.decode(res.elements['d:href'].text),
                  :created => res.elements[prop + 'd:creationdate'].text,
                  :updated => res.elements[prop + 'd:getlastmodified'].text,
                  :size => size,
                  :is_file => size > 0}
      end
      return files
    end

    def copy(from, to)
      move_copy(:copy, from, to)
    end
    alias_method :cp, :copy

    def move(from, to)
      move_copy(:move, from, to)
    end
    alias_method :mv, :move

    def delete(path)
      send_request(:delete, {:path => path})
    end
    alias_method :del, :delete

    def set_public(path)
      body = '<propertyupdate xmlns="DAV:"><set><prop><public_url xmlns="urn:yandex:disk:meta">true</public_url></prop></set></propertyupdate>'
      send_request(:proppatch, {:path => path, :body => body})
      xml = REXML::Document.new(@response.body)
      return xml.elements['d:multistatus/d:response/d:propstat/d:prop/public_url'].text
    end

    def set_private(path)
      body = '<propertyupdate xmlns="DAV:"><remove><prop><public_url xmlns="urn:yandex:disk:meta" /></prop></remove></propertyupdate>'
      send_request(:proppatch, {:path => path, :body => body})
      xml = REXML::Document.new(@response.body)
      return xml.elements['d:multistatus/d:response/d:propstat/d:prop/public_url'].text.nil?
    end

    # preview
    def preview(path, size, save_to)
      send_request(:get, {:path => path, :preview => size})
      File.open(File.join(save_to, path.split('/').last), 'w'){|f| f.write(@response.body)}
    end

    ########## private ##########
    private

    def create_dest(from, to)
      prop = properties(from)
      to = prop[:is_file] ? to.gsub(/\/$/,'') + '/' + prop[:name] : to
      return '/' + to
    end

    def move_copy(method, from, to)
      send_request(method, {:path => from,
                            :headers => {'Destination' => create_dest(from, to)}})
    end

    def send_propfind(depth, options = {})
      headers = {:headers => {'Depth' => depth.to_s,
                              'Content-Type' => 'text/xml; charset="utf-8"'}}
      send_request(:propfind, options.merge!(headers))
    end

    def send_request(method, args = {})
      # headers
      headers = {'Authorization' => @token}
      headers.merge!(args[:headers]) if args[:headers]
      uri = URI.parse(YandexDisk::API_URL)
      # path
      path = ''
      begin
        unless args[:path].blank?
          path = URI.encode( args[:path].split('/').reject{|it| it.blank?}.join('/') )
          raise Exception if path.empty?
          # image preview
          path << "?preview&size=#{args[:preview]}" if args[:preview]
        end
      rescue Exception => e
        raise RequestError, 'Path has bad format.'
      end
      request_path = uri.request_uri + path
      # init
      http = Net::HTTP.new(uri.host, uri.port)
      # ssl
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      # debug
      http.set_debug_output($stderr) if YandexDisk::DEBUG
      # method
      req = nil
      case method
        when :put then
          req = Net::HTTP::Put.new(request_path, headers)
          req.body_stream = Chunked.new(@file, args[:chunk_size])
        when :get then
          req = Net::HTTP::Get.new(request_path, headers)
        when :mkcol then
          req = Net::HTTP::Mkcol.new(request_path, headers)
        when :propfind then
          req = Net::HTTP::Propfind.new(request_path, headers)
        when :copy  then
          req = Net::HTTP::Copy.new(request_path, headers)
        when :move  then
          req = Net::HTTP::Move.new(request_path, headers)
        when :delete then
          req = Net::HTTP::Delete.new(request_path, headers)
        when :proppatch
          req = Net::HTTP::Proppatch.new(request_path, headers)
        else
          raise RequestError, "Method #{method} not supported."
      end
      # start
      req.body = args[:body] if args[:body]
      http.start{|h| @response = h.request(req) }
      successful?(method, request_path)
    end

    def successful?(method, path)
      if [200, 201, 207].include?(@response.code.to_i)      ||
         @response.body.include?('resource already exists') ||
         (method == :delete && @response.body.include?('resource not found'))
        true
      else
        raise RequestError, "#{@response.code.to_i} #{@response.message}: #{@response.body} on #{path}"
      end
    end
  end

end