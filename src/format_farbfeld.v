module vimage

const farbfeld_signature = [u8(0x66), 0x61, 0x72, 0x62, 0x66, 0x65, 0x6C, 0x64]

pub struct FarbfeldOptions {}

fn read_farbfeld(data []u8) (?Image, ?ImageOptions) {
	mut offset := 8
	mut image := Image{
		width:  read_u32(data[offset..offset + 4], big_endian)
		height: read_u32(data[offset + 4..offset + 8], big_endian)
	}
	image_options := ImageOptions(FarbfeldOptions{})
	offset += 8
	for offset < data.len {
		image.pixels << Pixel(Truecolor{
			red:   read_u16(data[offset..offset + 2], big_endian)
			green: read_u16(data[offset + 2..offset + 4], big_endian)
			blue:  read_u16(data[offset + 4..offset + 6], big_endian)
			alpha: read_u16(data[offset + 6..offset + 8], big_endian)
		})
		offset += 8
	}
	return image, image_options
}

fn write_farbfeld(image Image, image_options ImageOptions) []u8 {
	mut data := []u8{cap: farbfeld_signature.len + 16 + image.pixels.len}
	data << farbfeld_signature
	data << write_u32(image.width, big_endian)
	data << write_u32(image.height, big_endian)
	for i := 0; i < image.pixels.len; i++ {
		pixel := image.pixels[i]
		match pixel {
			Truecolor {
				data << write_u16(pixel.red, big_endian)
				data << write_u16(pixel.green, big_endian)
				data << write_u16(pixel.blue, big_endian)
				data << write_u16(pixel.alpha, big_endian)
			}
			Grayscale {
				data << write_u16(pixel.gray, big_endian)
				data << write_u16(pixel.gray, big_endian)
				data << write_u16(pixel.gray, big_endian)
				data << write_u16(pixel.alpha, big_endian)
			}
			Index {
				palette_color := image.palette[pixel.index]
				data << write_u16(palette_color.red, big_endian)
				data << write_u16(palette_color.green, big_endian)
				data << write_u16(palette_color.blue, big_endian)
				data << write_u16(palette_color.alpha, big_endian)
			}
		}
	}
	return data
}
