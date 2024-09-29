module vimage

const farbfeld_signature = [u8(0x66), 0x61, 0x72, 0x62, 0x66, 0x65, 0x6C, 0x64]

pub struct FarbfeldOptions {}

fn read_farbfeld(data []u8) (?Image, ?ImageOptions) {
	mut offset := 8
	mut image := Image{
		width:  read_u32(data[offset..offset + 4], true)
		height: read_u32(data[offset + 4..offset + 8], true)
	}
	image_options := ImageOptions(FarbfeldOptions{})
	offset += 8
	for offset < data.len {
		image.pixels << Pixel(Truecolor{
			red:   read_u16(data[offset..offset + 2], true)
			green: read_u16(data[offset + 2..offset + 4], true)
			blue:  read_u16(data[offset + 4..offset + 6], true)
			alpha: read_u16(data[offset + 6..offset + 8], true)
		})
		offset += 8
	}
	return image, image_options
}

fn write_farbfeld(image Image, image_options ImageOptions) []u8 {
	mut data := []u8{cap: farbfeld_signature.len + 16 + image.pixels.len}
	data << farbfeld_signature
	data << write_u32(image.width, true)
	data << write_u32(image.height, true)
	for i := 0; i < image.pixels.len; i++ {
		pixel := image.pixels[i]
		match pixel {
			Truecolor {
				data << write_u16(pixel.red, true)
				data << write_u16(pixel.green, true)
				data << write_u16(pixel.blue, true)
				data << write_u16(pixel.alpha, true)
			}
			Grayscale {
				data << write_u16(pixel.gray, true)
				data << write_u16(pixel.gray, true)
				data << write_u16(pixel.gray, true)
				data << write_u16(pixel.alpha, true)
			}
			Index {
				palette_color := image.palette[pixel.index]
				data << write_u16(palette_color.red, true)
				data << write_u16(palette_color.green, true)
				data << write_u16(palette_color.blue, true)
				data << write_u16(palette_color.alpha, true)
			}
		}
	}
	return data
}
