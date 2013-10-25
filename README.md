## Yandex Disk gem
An easy-to-use client library for Yandex Disk API.
## Usage
Include to project `require 'yandex_disk'` and login `yd = YandexDisk.login(login, pwd)`
### Available methods:
* `yd.upload(file, path, options)` 

  Upload file and return true if success else raise RequestError
  
  **options:**
  
  `:chunk_size` file chunk size, default is 100
   
  `:force` create path if not exist, default raise error
   
  **example:**
   `yd.upload('/home/graph.pdf', 'my/work', {:force => true, :chunk_size => 500})`, will create "my/work" directory and upload file to "/my/work/graph.pdf" using chunk size 500 per request
* `yd.download(file, save_path)`

  Download file and return true if success else raise RequestError
  
  **example:**
   `yd.download('/my/work/graph.pdf', '/home')`, will download file and save to "/home/graph.pdf"
* `yd.create_path(path)`

  Create path and return true if success else raise RequestError
  
  **alias:** mkdir
  
  **example:**
   `yd.mkdir('/my/work')`, will be create "/my/work" path
* `yd.size`

  Get available and used space, return Hash `{:available, :used }` if success else raise RequestError
  
  **example:**
  
   `s = yd.size`
   
   `p s[:available], s[:used]`
   
* `yd.exist?(file)`

  Check if file exist, return true if file exist else false
  
  **example:**
   `p yd.exist?('/home/graph.pdf') # => true`
* `yd.properties(file)`

  Get file properties, return Hash `{:name, :created, :updated, :type, :size, :is_file, :public_url}` if success else raise RequestError
  
  **example:**
  
   `prop = yd.properties('/home/graph.pdf')`
   
   `p prop[:is_file] # => true`
* `yd.files(path)`

  Return list of files properties in directory, Array with Hash `[{:name, :created, :updated, :type, :size, :is_file}]` if success else raise RequestError
  
  **example:**
  
   `files = yd.properties('/home')`
   
   `p files[0][:name] # => home`
   
   for defaults response include properties for root directory ("home" in example). If you not need this dir properties, just set second argument to false
   
   `files = yd.properties('/home', false)`
   
   `p files[0][:name] # => graph.pdf`
