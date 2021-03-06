require 'net/http'
require 'uri'
require 'openssl'
require 'zlib'
require 'base64'
require 'rexml/document'

require 'yandex_disk/cfg'
require 'yandex_disk/ext'
require 'yandex_disk/chunked'

module YandexDisk
  class RequestError < Exception; end
  class BadFormat < Exception; end

  class Api

    def initialize(login, pwd)
      @token = 'Basic ' + Base64.encode64("#{login}:#{pwd}")
    end

    # Example:
    #   yd.upload('/home/graph.pdf', 'my/work')
    #   => true
    #
    # Arguments:
    #   file: path to file
    #   path: path to yandex disk directory. If path not present - save to root
    #   options:
    #      chunk_size: file chunk size (default is 100)
    #      force: create path structure if not exist (raise <b>RequestError</b> if <b>path</b> not exist for default)
    def upload(file, path = '', options = {})
      # valid file?
      raise RequestError, "File not found." if file.nil? || !File.file?(file)
      # create path
      create_path(path) if options[:force]
      options[:chunk_size] ||= 1024
      @file = File.open(file)
      options[:headers] = {'Expect' => '100-continue',
                           'Transfer-Encoding' => 'chunked',
                           'content-type' => 'application/binary'}

      send_request(:put, options.merge({:path => File.join( path, File.basename(file) )}))
      @file.close
      return true
    end

    # Example:
    #   yd.download('/home/graph.pdf', '/home')
    #   => true (or file content)
    #
    # Arguments:
    #   file: path to yandex disk file
    #   save_path: path to save. If save_path not present - return file content
    def download(file, save_path = nil)
      option = {:path => file,
                :headers => {'TE' => 'chunked',
                             'Accept-Encoding' => 'gzip'}}

      send_request(:get, option)

      # unzip if zipped
      if gzip?(@response.header['Content-Encoding'])
        s_io = StringIO.new(@response.body)
        gz = Zlib::GzipReader.new(s_io)
        data = gz.read
      else
        data = @response.body
      end

      if save_path
        File.open(File.join(save_path, file.split('/').last), 'w'){|f| f.write(data)}
        return true
      else
        return data
      end
    end

    # Example:
    #   yd.create_path('/home/my/photos')
    #   => true
    #
    # Arguments:
    #   path: path to yandex disk directory hierarchy
    def create_path(path)
      c_path = ''
      path.split('/').each do |p|
        next if p.empty?
        c_path << p + '/'
        send_request(:mkcol, :path => c_path)
      end
    end
    alias_method :mkdir, :create_path

    # Example:
    #   yd.size
    #   => {:available => 312312, :used => 3123}
    # Arguments:
    #   options:
    #      readable: return size in human readable format e.g, 100K 128M 1G (false for default)
    def size(options = {})
      body = '<?xml version="1.0" encoding="utf-8"?><D:propfind xmlns:D="DAV:"><D:prop><D:quota-available-bytes/><D:quota-used-bytes/></D:prop></D:propfind>'
      send_propfind(0, :body => body)
      xml = REXML::Document.new(@response.body)
      prop = 'd:multistatus/d:response/d:propstat/d:prop/'
      available_b = xml.elements[prop + 'd:quota-available-bytes'].text.to_i
      used_b = xml.elements[prop + 'd:quota-used-bytes'].text.to_i

      return {:available => available_b.to_readable(options[:h_size]),
             :used => used_b.to_readable(options[:h_size])}
    end

    # Example:
    #   yd.exist?('/home/graph.pdf')
    #   => true
    #
    # Arguments:
    #   path: path to yandex disk directory or file
    def exist?(path)
      body = '<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><displayname/></prop></propfind>'
      send_propfind(0, :path => path, :body => body)
    rescue RequestError
      return false
    end

    # Example:
    #   yd.properties('/home/graph.pdf')
    #   =>
    #       {:name => 'graph.pdf',
    #       :created => (Time),
    #       :updated => (Time),
    #       :type => 'pdf',
    #       :size => 42432,
    #       :is_file => true,
    #       :public_url => nil}
    #
    # Arguments:
    #   path: path to yandex disk directory or file
    #   h_size: return size in human readable format e.g, 100K 128M 1G (false for default)
    def properties(path, options = {})
      body = '<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><displayname/><creationdate/><getlastmodified/><getcontenttype/><getcontentlength/><public_url xmlns="urn:yandex:disk:meta"/></prop></propfind>'
      send_propfind(0, :path => path, :body => body)
      prop = 'd:multistatus/d:response/d:propstat/d:prop/'
      xml = REXML::Document.new(@response.body)
      type = xml.elements[prop + 'd:getcontenttype'].text
      size = xml.elements[prop + 'd:getcontentlength'].text.to_i

      return {:name => xml.elements[prop + 'd:displayname'].text,
              :created => xml.elements[prop + 'd:getlastmodified'].text,
              :updated => xml.elements[prop + 'd:getlastmodified'].text,
              :type => type ? type : 'dir',
              :size => size.to_readable(options[:h_size]),
              :is_file => size > 0,
              :public_url => xml.elements[prop + 'public_url'].text}
    end

    # Example:
    #   yd.files('/home')
    #   =>
    #       [{:name => 'graph.pdf',
    #       :created => (Time),
    #       :updated => (Time),
    #       :type => 'pdf',
    #       :size => 42432,
    #       :is_file => true}]
    #
    # Arguments:
    #   path: path to yandex disk directory (default is <b>root</b>)
    #   root: include information of root directory or not (<b>false</b> for default)
    #   h_size: return size in human readable format e.g, 100K 128M 1G (false for default)
    def files(path = '', options = {})
      send_propfind(1, :path => path)
      xml = REXML::Document.new(@response.body)
      prop = 'd:propstat/d:prop/'
      files = []
      xml.elements.each('d:multistatus/d:response') do |res|
        name = URI.decode(res.elements[prop + 'd:displayname'].text)
        next if !options[:root] && path.split('/').last == name
        size = res.elements[prop + 'd:getcontentlength'].text.to_i rescue 0

        files << {:name => name,
                  :path => URI.decode(res.elements['d:href'].text),
                  :created => res.elements[prop + 'd:creationdate'].text,
                  :updated => res.elements[prop + 'd:getlastmodified'].text,
                  :size => size.to_readable(options[:h_size]),
                  :is_file => size > 0}
      end
      return files
    end
    alias_method :ls, :files

    # Example:
    #   yd.copy('/home/graph.pdf', 'my/work')
    #   => true
    #
    # Arguments:
    #   from: path to yandex disk directory or file
    #   to: path to yandex disk directory
    def copy(from, to)
      move_copy(:copy, from, to)
    end
    alias_method :cp, :copy

    # Example:
    #   yd.move('/home/graph.pdf', 'my/work')
    #   => true
    #
    # Arguments:
    #   from: path to yandex disk directory or file
    #   to: path to yandex disk directory
    def move(from, to)
      move_copy(:move, from, to)
    end
    alias_method :mv, :move

    # Example:
    #   yd.delete('/home/graph.pdf')
    #   => true
    #
    # Arguments:
    #   path: path to yandex disk directory or file
    def delete(path)
      send_request(:delete, :path => path)
    end
    alias_method :del, :delete

    # Example:
    #   yd.set_public('/home/graph.pdf')
    #   => http://yadi.sk/d/#############
    #
    # Arguments:
    #   path: path to yandex disk directory or file
    def set_public(path)
      body = '<propertyupdate xmlns="DAV:"><set><prop><public_url xmlns="urn:yandex:disk:meta">true</public_url></prop></set></propertyupdate>'
      send_request(:proppatch, :path => path, :body => body)
      xml = REXML::Document.new(@response.body)
      return xml.elements['d:multistatus/d:response/d:propstat/d:prop/public_url'].text
    end

    # Example:
    #   yd.set_private('/home/graph.pdf')
    #   => true
    #
    # Arguments:
    #   path: path to yandex disk directory or file
    def set_private(path)
      body = '<propertyupdate xmlns="DAV:"><remove><prop><public_url xmlns="urn:yandex:disk:meta" /></prop></remove></propertyupdate>'
      send_request(:proppatch, :path => path, :body => body)
      xml = REXML::Document.new(@response.body)
      return xml.elements['d:multistatus/d:response/d:propstat/d:prop/public_url'].text.nil?
    end

    # Example:
    #   yd.preview('/home/cat.jpg', 128, '/home/photo')
    #   => true
    #
    # Arguments:
    #   path: path to yandex disk file
    #   size: preview size (for details visit http://api.yandex.com/disk/doc/dg/reference/preview.xml)
    #   save_to: path to save
    def preview(path, size, save_to)
      send_request(:get, :path => path, :preview => size.to_s)
      File.open(File.join(save_to, path.split('/').last), 'w'){|f| f.write(@response.body)}
    end

    ########## private ##########
    private

    def gzip?(type)
      type == 'gzip'
    end

    def create_dest(from, to)
      prop = properties(from)
      to = prop[:is_file] ? to.gsub(/\/$/,'') + '/' + prop[:name] : to
      return '/' + to
    end

    def request_path(path, preview)
      if path.blank?
        return ''
      else
        path = URI.encode( path.split('/').reject{|it| it.blank?}.join('/') )
        raise Exception if path.empty?
        # image preview
        path << "?preview&size=#{preview}" if preview
        return path
      end
    rescue Exception
      raise BadFormat, 'Path has bad format.'
    end

    def init_request(method)
      case method
        when :put then Net::HTTP::Put
        when :get then Net::HTTP::Get
        when :mkcol then Net::HTTP::Mkcol
        when :propfind then Net::HTTP::Propfind
        when :copy  then Net::HTTP::Copy
        when :move  then Net::HTTP::Move
        when :delete then Net::HTTP::Delete
        when :proppatch then Net::HTTP::Proppatch
        else raise RequestError, "Method #{method} not supported."
      end
    end

    def move_copy(method, from, to)
      send_request(method, :path => from,
                           :headers => {'Destination' => create_dest(from, to)})
    end

    def send_propfind(depth, options = {})
      headers = {:headers => {'Depth' => depth.to_s,
                              'Content-Type' => 'text/xml; charset="utf-8"'}}
      send_request(:propfind, options.merge!(headers))
    end

    # return true if successful
    def send_request(method, args = {})
      # headers
      headers = {'Authorization' => @token,
                 'User-Agent' => "Ruby client library v#{YandexDisk::VERSION}"}
      headers.merge!(args[:headers]) if args[:headers]
      uri = URI.parse(YandexDisk::API_URL)
      # path
      path = uri.request_uri + request_path(args[:path], args[:preview])
      # init
      http = Net::HTTP.new(uri.host, uri.port)
      # ssl
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      # debug
      http.set_debug_output($stderr) if YandexDisk::DEBUG
      # request
      req = init_request(method).new(path, headers)
      req.body_stream = Chunked.new(@file, args[:chunk_size]) if method == :put
      req.body = args[:body] if args[:body]
      # start
      http.start{|h| @response = h.request(req) }
      successful?(method, path)
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