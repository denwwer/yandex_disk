## Yandex Disk gem
An easy-to-use client library for Yandex Disk API.
Has any issue or suggestion please write about it [here](https://github.com/denwwer/yandex_disk/issues)
## Usage
Include to project and login

    require 'yandex_disk'
    yd = YandexDisk.login(login, pwd)`
#### Upload file

    yd.upload(file, path, options)
return true if success else raise RequestError

**options:**

`:chunk_size` file chunk size, default is 100

`:force` create path if not exist, default raise error

**example:**

    yd.upload('/home/graph.pdf', 'my/work', {:force => true, :chunk_size => 500})
    # will create "my/work" directory and upload file to "/my/work/graph.pdf" using chunk size 500 per request

#### Download file

    yd.download(file, save_path)

return true if success else raise RequestError

  **example:**

    yd.download('/my/work/graph.pdf', '/home') # download file to "/home/graph.pdf"
#### Create path

    yd.create_path(path)

return true if success else raise RequestError

  **alias:** `mkdir`

  **example:**

    yd.mkdir('/my/work') # create "/my/work" path
#### Get available and used space

    yd.size

return Hash `{:available, :used }` if success else raise RequestError

  **example:**

    s = yd.size
    p s[:available], s[:used]
#### File exist?

    yd.exist?(file)

return true if file exist else false

  **example:**

    p yd.exist?('/home/graph.pdf') # => true
#### Get file properties

    yd.properties(file)

return Hash `{:name, :created, :updated, :type, :size, :is_file, :public_url}` if success else raise RequestError

  **example:**

    prop = yd.properties('/home/graph.pdf')
    p prop[:is_file] # => true
#### Return list of files properties in directory

    yd.files(path)

  return Array with Hash `[{:name, :created, :updated, :type, :size, :is_file}]` if success else raise RequestError

  **example:**

    files = yd.properties('/home')
    p files[0][:name] # => home

   for default response include properties for root directory ("home" in example). If you not need this dir properties, just set second argument to false

    files = yd.properties('/home', false)
    p files[0][:name] # => graph.pdf
#### Copy file or directory

    yd.copy(from, to)

return true if successful else raise RequestError

  **alias:** `cp`

  **example:**

    yd.copy('/home/graph.pdf', '/backup') # copy "graph.pdf" to "backup" directory
#### Move file or directory

    yd.move(from, to)

return true if successful else raise RequestError

  **alias:** `mv`

  **example:**

    yd.move('/home/graph.pdf', '/pdfs') # move "graph.pdf" to "pdfs" directory
#### Delete file or directory

    yd.delete(path)

return true if successful else raise RequestError

  **alias:** `del`

  **example:**

    yd.delete('/home/graph.pdf') # delete "graph.pdf"
#### Set public access for file or directory

    yd.set_public(path)

return public url if successful else raise RequestError

  **example:**

    yd.set_public('/home/graph.pdf') # => http://yadi.sk/d/FTb3fL0049Xt0
#### Set private file or directory

    yd.set_private(path)

return true if successful else false

  **example:**

    yd.set_private('/home/graph.pdf') # => true
#### Get image preview

    preview(path, size, save_to)

save image if successful else raise RequestError
 size supported value:

    T-shirt size (like in Yandex.Fotki), such as size=M. Yandex.Disk returns a preview in the size you selected:
    XXXS — 50 pixels on each side (square).
    XXS — 75 pixels on each side (square).
    XS — 100 pixels on each side (square).
    S — 150 pixels wide, preserves original aspect ratio.
    M — 300 pixels wide, preserves original aspect ratio.
    L — 500 pixels wide, preserves original aspect ratio.
    XL — 800 pixels wide, preserves original aspect ratio.
    XXL — 1024 pixels wide, preserves original aspect ratio.
    XXXL — 1280 pixels wide, preserves original aspect ratio.

    A number, such as size=128.
    Yandex.Disk returns a preview with this width. If the specified width is more than 100 pixels, the preview preserves the aspect ratio of the original image.
    Otherwise, the preview is additionally modified: the largest possible square section is taken from the center of the image to scale to the specified width.

    Exact dimensions, such as size=128x256.
    Yandex.Disk returns a preview with the specified dimensions. The largest possible section with the specified width/height ratio is taken from the center of the original image (in the example, the ratio is 128/256 or 1/2). Then this section of the image is scaled to the specified dimensions. See the example with exact dimensions below.

    Exact width or height, such as size=128x or size=x256.
    Yandex.Disk returns a preview with the specified width or height that preserves the aspect ratio of the original image.
*View the original [api page](http://api.yandex.com/disk/doc/dg/reference/preview.xml) for details.*

  **example:**

    yd.preview('/photo/car.jpg', 'm', '/home') # save "car.jpg" with 300 pixels wide to home directory