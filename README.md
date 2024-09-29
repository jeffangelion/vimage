# vimage (work in progress)
Image manipulation library for V programming language

## License
GNU Lesser General Public License v3.0 or later (see [LICENSE](./LICENSE.md))

## Usage (hypothetical)
```v
// Please note that module will not be added to VPM until version 1.0.0 is released
import jeffangelion.vimage

image, _ := vimage.read_from_file('path/to/image_file') or {
    println('failed to read from file')
}

// You can also read image format from []u8{} (i.e. downloaded from website)
cats, _ := vimage.read_from_array(cool_image_from_network) or {
    println('image is too cool for vimage')
}
```

## Roadmap to 1.0.0
- [X] farbfeld support

- [ ] basic PNG support

- [ ] basic GIM support

- [X] get/set pixels by coordinates

- [X] invert colors

- [X] rotate/flip image

## Roadmap to future releases
- [ ] more image formats

- [ ] complete support of included formats (i.e. PNG Adam7 interlace)

## Need something working and more simple for your project? Check this out

|Image format |VPM command                 |Module repo                        |
|-------------|----------------------------|-----------------------------------|
|PNG          |`v install Henrixounez.vpng`|https://github.com/Henrixounez/vpng|
|Other formats|`¯\_(ツ)_/¯`                |Feel free to add via PR/issues     |