# Project structure

|File name      |Description                                    |
|---------------|-----------------------------------------------|
|`image.v`      |Image struct and ImageOptions sum type         |
|`read_write*.v`|Necessary functions for read/write data        |
|`format_*.v`   |Fuctions for read/write respective image format|

## `format_*.v` structure

1. Image format signatures/magic numbers as `pub const ${format_name}_signature []u8{}`
2. Image format specific options as `pub struct ${FormatName}Options` also should be a part of `ImageOptions` sum type
3. Image format read function as `fn read_${format_name}(data []u8) (?Image, ?ImageOptions) {}`
4. Image format write function as `fn write_${format_name}(image Image, image_options ImageOptions) []u8 {}`
