## Yandex Disk gem
An easy-to-use client library for Yandex Disk API.
## Usage
include to project `require 'yandex_disk'`
login `yd = YandexDisk.login(login, pwd)`
### Available methods:
* upload file `yd.upload(file, path, options)`
  return: true if success else raise RequestError
  options:
   `:chunk_size` file chunk size, default is 100
   `:force` create path if not exist, default raise error
  Example:
   `yd.upload('/home/graph.pdf', 'my/work', {:force => true, :chunk_size => 500})`, will create "my/work" directory and upload file to "/my/work/graph.pdf" using chunk size 500 per request
* download file `yd.download(file, save_path)`
  return: true if success else raise RequestError
  Example:
   `yd.download('/my/work/graph.pdf', '/home')`, will be download file and save to "/home/graph.pdf"
* create path `yd.create_path(path)`
  return: true if success else raise RequestError
  alias: mkdir
  Example:
   `yd.mkdir('/my/work')`, will be create "/my/work" path
* get available and used space `yd.size`
  return: Hash `{:available, :used }` if success else raise RequestError
  Example:
   `s = yd.size`
   `p s[:available], s[:used]`
* check if file exist `yd.exist?(file)`
  return: true if file exist else false
  Example:
   `p yd.exist?('/home/graph.pdf') # => true`
* file properties `yd.properties(file)`
  return: Hash `{:name, :created, :updated, :type, :size, :is_file, :public_url}` if success else raise RequestError
  Example:
   `prop = yd.properties('/home/graph.pdf')`
   `p prop[:is_file] # => true`
* return list of files properties in directory `yd.files(path)`
  return: Array with Hash `[{:name, :created, :updated, :type, :size, :is_file}]` if success else raise RequestError
  Example:
   `files = yd.properties('/home')`
   `p files[0][:name] # => home`
   for defaults response include properties for root directory ("home" in example). If you not need this dir properties, just set second argument to false
   `files = yd.properties('/home', false)`
   `p files[0][:name] # => graph.pdf`