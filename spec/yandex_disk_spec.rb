#encoding: UTF-8
require 'spec_helper'
require 'fastimage'

describe YandexDisk do

  it 'should return version' do
    YandexDisk.version.should equal YandexDisk::VERSION
  end

  describe 'validate' do
    it 'authorization' do
      yd = YandexDisk.login('', '')
      expect{yd.size}.to raise_error YandexDisk::RequestError, /401 Unauthorized/
    end

    it 'wrong file' do
      yd = YandexDisk.login('', '')
      expect{yd.upload('not/exist/file')}.to raise_error YandexDisk::RequestError, /File not found/
    end

    it 'wrong path' do
      yd = YandexDisk.login('', '')
      expect{yd.create_path('/   / / / /f // / ')}.to raise_error YandexDisk::BadFormat, /Path has bad format/
    end
  end

  describe 'api' do
    before(:each) do
      @yd = YandexDisk.login(LOGIN, PWD)
    end

    describe 'size' do
      it 'in bytes' do
        size = @yd.size
        expect(size[:used] > 0 && size[:available] > 0).to be_true
      end

      it 'in readable format' do
        size = @yd.size(:h_size => true)
        mask = /Byte|KB|MB|GB/
        expect(size[:used].match(mask)[0].empty? &&
               size[:available].match(mask)[0].empty?).to be_false
      end
    end

    it 'should return list of files' do
     @yd.files.each do |item|
        [:name, :path, :created, :updated, :size, :is_file].each{|res| item[res].to_s.should_not be_empty}
     end
    end

    describe 'properties' do
      it 'for file' do
        @yd.upload(@text_file, 'my', :force => true)
        properties = @yd.properties('my/' + File.basename(@text_file))
        [:created, :updated, :type, :size, :is_file].each{|res| properties[res].to_s.should_not be_empty}
        properties[:type].should eq 'text/plain'
      end

      it 'for directory' do
        dir = '/my/photo'
        @yd.create_path(dir)
        properties = @yd.properties(dir)
        properties[:is_file].should be_false
      end
    end

    describe 'directory' do
      it 'create' do
        dir = 'my/photos/cats'
        @yd.create_path(dir).should be_true
        @yd.properties(dir)[:is_file].should be_false
      end

      it 'copy' do
        # create directories with Cyrillic name
        src = 'файлы/старые'
        des = 'файлы/здесь новые'

        @yd.create_path(src)
        @yd.create_path(des)
        # create 2 files
        files = {'file1.txt' => 'data one', 'file2.txt' => 'data two'}
        files.each do |file, text|
          new_file = File.join(FILES_PATH, file)
          File.open(new_file, 'w'){|f| f.write(text)}
          @yd.upload(new_file, src).should be_true
        end
        # copy directory
        @yd.copy(src, des)
        # check files
        @yd.files(src).size.should eq 2
        # clear
        files.each{|file, text| File.delete( File.join(FILES_PATH, file) )}
      end
    end

    describe 'file' do
      it 'upload' do
        @yd.upload(@text_file, 'my', :force => true).should be_true
        @yd.exist?('my/' + File.basename(@text_file)).should be_true
      end

      describe 'download' do
        it 'save and validate' do
          @yd.upload(@text_file, 'my', :force => true).should be_true
          path = 'my/' + File.basename(@text_file)
          @yd.download(path, DOWNLOAD_PATH).should be_true
          expect( File.read( File.join(DOWNLOAD_PATH, File.basename(@text_file)) ) ).to eq(FILE_TEXT)
        end

        it 'return and validate' do
          @yd.upload(@text_file, 'my', :force => true).should be_true
          path = 'my/' + File.basename(@text_file)
          YandexDisk::Api.any_instance.stub(:response).and_return('xxx')
          @yd.download(path).should eq FILE_TEXT
        end

        it 'unzip file' do
          file = @text_file.gsub('.txt', '.gz')
          Zlib::GzipWriter.open(file) do |gz|
            gz.write File.read(@text_file)
          end

          @yd.upload(file, 'my', :force => true).should be_true
          path = 'my/' + File.basename(file)
          @yd.should_receive(:gzip?){ true }
          @yd.download(path).should eq FILE_TEXT
        end
      end

      it 'copy' do
        @yd.upload(@text_file, 'my', :force => true)
        f_name = File.basename(@text_file)
        file = 'my/' + f_name
        new_path = 'my/text'
        @yd.create_path(new_path).should be_true
        @yd.copy(file, new_path).should be_true
        # file still exist in src path
        @yd.exist?(file).should be_true
      end

      it 'move' do
        @yd.upload(@text_file, 'my', :force => true)
        f_name = File.basename(@text_file)
        file = 'my/' + f_name
        new_path = 'my/text'
        @yd.create_path(new_path)
        @yd.move(file, new_path).should be_true
        # file not exist in src path
        @yd.exist?(file).should be_false
      end

      it 'delete' do
        @yd.upload(@text_file)
        f_name = File.basename(@text_file)
        @yd.delete(f_name).should be_true
        @yd.exist?(f_name).should be_false
      end

      it 'set public'do
        @yd.upload(@image_file, 'my', :force => true)
        # mask: http://yadi.sk/d/#############
        expect(@yd.set_public('my/' + File.basename(@image_file)) =~ /http:\/\/yadi\.sk\/d\/.+/).to be_true
      end

      it 'set private'do
        @yd.upload(@text_file, 'my', :force => true)
        f_name = 'my/' + File.basename(@text_file)
        # mask: http://yadi.sk/d/#############
        expect(@yd.set_public(f_name) =~ /http:\/\/yadi\.sk\/d\/.+/).to be_true
        expect(@yd.set_private(f_name)).to be_true
      end

      describe 'preview' do
        before(:each)do
          @yd.upload(@image_file, 'my', :force => true).should be_true
          @f_name = File.basename(@image_file)
        end

        it 'should return image in M size'do
          @yd.preview('my/' + @f_name, 'm', DOWNLOAD_PATH).should be_true
          File.file?( File.join(DOWNLOAD_PATH, @f_name) ).should be_true
        end

        it 'should return image in 300x250 size'do
          @yd.preview('my/' + @f_name, '300x250', DOWNLOAD_PATH).should be_true
          FastImage.size( File.join(DOWNLOAD_PATH, @f_name) ).should eq [300, 250]
        end

        it 'should return image in 128 pixels wide'do
          @yd.preview('my/' + @f_name, 128, DOWNLOAD_PATH).should be_true
          FastImage.size( File.join(DOWNLOAD_PATH, @f_name) )[0].should eq 128
        end
      end
    end

    it 'should catch wrong method' do
      expect { @yd.send :init_request, :none }.to raise_error YandexDisk::RequestError, /Method none not supported/
    end
  end
end