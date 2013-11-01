## ChangeLog
### v1.1.1
* gem size decrease
### v1.1.0 (yanked)
* added ability to return size in human readable format (for default in bytes)

 `size`, `properties`, `files` methods now has option `:h_size => true` (humanize size) to return readable format: 15 Byte, 100 KB, 128 MB, 1 GB.
 
 **example**

         s = yd.size(:h_size => true)
         p s[:available], s[:used] => 7.9 GB, 100 MB
         ####
         prop = yd.properties('/home/graph.pdf', {:h_size => true})
         p prop[:size] # => 50 MB
         ###
         files = yd.files('/home', {:h_size => true})
         p files[0][:size] => 50 MB

 IMPORTANT!

 Method `files` changed second argument, now is `Hash`, and dont include root directory for default:

         # Old
         # dont include root directory
         yd.files('/home', false)
         # include root directory
         yd.files('/home')
         # New
         # dont include root directory
         yd.files('/home')
         # include root directory
         yd.files('/home', {:root => true})

* added alias method `ls` to `files`:

         yd.ls('/home')
