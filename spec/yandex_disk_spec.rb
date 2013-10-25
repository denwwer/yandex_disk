#encoding: UTF-8
require 'spec_helper'
require 'net/http'
require 'uri'
require 'fastimage'

describe YandexDisk do

  it 'should return version' do
    YandexDisk.version.should equal YandexDisk::VERSION
  end

  describe 'validate' do
    it 'authorization' do
      yd = YandexDisk.login('', '')
      expect{yd.size}.to raise_error YandexDisk::RequestError
    end

    it 'file' do
      yd = YandexDisk.login('', '')
      expect{yd.upload('not/exist/file')}.to raise_error YandexDisk::RequestError
    end
  end

  describe 'api' do
    before(:each) do
      @yd = YandexDisk.login(LOGIN, PWD)
    end

    it 'should return available and used space' do
      size = @yd.size
      expect(size[:used] > 0 && size[:available] > 0).to be_true
    end

    it 'should return list of files' do
     @yd.files.each do |item|
        [:name, :path, :created, :updated, :size, :is_file].each{|res| expect(!item[res].to_s.empty?).to be_true}
     end
    end

    it 'should return file or dir properties' do
      # file
      @yd.upload(@text_file, 'my', {:force => true})
      properties1 = @yd.properties('my/' + File.basename(@text_file))
      [:created, :updated, :type, :size, :is_file].each{|res| expect(properties1[res].to_s.empty?).to be_false}
      properties1[:type].should eq 'text/plain'
      # dir
      dir = '/my/photo'
      @yd.create_path(dir)
      properties2 = @yd.properties(dir)
      properties2[:is_file].should be_false
      clear!
    end

    describe 'directory' do
      it 'should be created' do
        dir = 'my/photos/cats'
        @yd.create_path(dir).should be_true
        @yd.properties(dir)[:is_file].should be_false
      end

      it 'should be copied' do
        # create directories with Cyrillic name
        src = 'my/старые файлы'
        des = 'my/здесь новые файлы'

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
        @yd.files(src, false).size.should eq 2
        files.each do |file, text|
          download_and_validate(File.join(des, file), text)
        end
        # clear
        files.each{|file, text| File.delete( File.join(FILES_PATH, file) )}
      end

      after(:each) do
        clear!
      end
    end

    describe 'file' do
      it 'should be uploaded' do
        @yd.upload(@text_file, 'my', {:force => true}).should be_true
      end

      it 'should be downloaded and valid' do
        @yd.upload(@text_file, 'my', {:force => true}).should be_true
        path = 'my/' + File.basename(@text_file)
        download_and_validate(path)
      end
      # its related to copy dir
      it 'should by copied to new directory' do
        @yd.upload(@text_file, 'my', {:force => true})
        f_name = File.basename(@text_file)
        file = 'my/' + f_name
        new_path = 'my/text'
        @yd.create_path(new_path)
        @yd.copy(file, new_path)
        # file still exist in src path
        @yd.exist?(file).should be_true
        download_and_validate(File.join(new_path, f_name))
      end

      it 'should by moved to new directory' do
        @yd.upload(@text_file, 'my', {:force => true})
        f_name = File.basename(@text_file)
        file = 'my/' + f_name
        new_path = 'my/text'
        @yd.create_path(new_path)
        @yd.move(file, new_path)
        # file not exist in src path
        @yd.exist?(file).should be_false
        download_and_validate(File.join(new_path, f_name))
      end

      it 'should by deleted' do
        # upload file
        @yd.upload(@text_file)
        f_name = File.basename(@text_file)
        download_and_validate(f_name)
        @yd.delete(f_name)
        @yd.exist?(f_name).should be_false
      end

      it 'should be public'do
        @yd.upload(@image_file, 'my', {:force => true})
        # example: http://yadi.sk/d/FTb3fLiI49Xt0
        expect(@yd.set_public('my/' + File.basename(@image_file)) =~ /http:\/\/yadi\.sk\/d\/.+/).to be_true
      end

      it 'should be private'do
        @yd.upload(@text_file, 'my', {:force => true})
        f_name = 'my/' + File.basename(@text_file)
        # example: http://yadi.sk/d/FTb3fLiI49Xt0
        expect(@yd.set_public(f_name) =~ /http:\/\/yadi\.sk\/d\/.+/).to be_true
        expect(@yd.set_private(f_name)).to be_true
      end

      describe 'preview' do
        before(:each)do
          @yd.upload(@image_file, 'my', {:force => true}).should be_true
          @f_name = File.basename(@image_file)
        end

        it 'should return image in M size'do
          @yd.preview('my/' + @f_name, 'm', DOWNLOAD_PATH)
          File.file?( File.join(DOWNLOAD_PATH, @f_name) ).should be_true
        end

        it 'should return image in 300x250 size'do
          @yd.preview('my/' + @f_name, '300x250', DOWNLOAD_PATH)
          FastImage.size( File.join(DOWNLOAD_PATH, @f_name) ).should eq [300, 250]
        end
      end

      after(:each) do
        clear!
      end
    end

  end

  def download_and_validate(download_file, text = FILE_TEXT)
    @yd.download(download_file, DOWNLOAD_PATH).should be_true
    file = download_file.split('/').last
    expect( File.read( File.join(DOWNLOAD_PATH, file) ) ).to eq(text)
  end

end