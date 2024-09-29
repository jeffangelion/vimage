module vimage

import log
import os

pub fn read_from_file(filename string) (?Image, ?ImageOptions) {
	data := os.read_bytes(filename) or {
		log.error('vimage: failed to read file')
		panic(err)
	}
	image, image_options := read_from_array(data)
	return image, image_options
}

pub fn read_from_array(data []u8) (?Image, ?ImageOptions) {
	return match data[..8] {
		png_signature {
			log.info('vimage: file format -- PNG')
			read_png(data)
		}
		gim_big_endian_signature {
			log.info('vimage: file format -- GIM, big endian')
			read_gim(data)
		}
		gim_little_endian_signature {
			log.info('vimage: file format -- GIM, little endian')
			read_gim(data)
		}
		farbfeld_signature {
			log.info('vimage: file format -- Farbfeld')
			read_farbfeld(data)
		}
		else {
			match data[..2] {
				bmp_big_endian_signature {
					log.info('vimage: file format -- BMP, big endian')
					read_bmp(data)
				}
				bmp_little_endian_signature {
					log.info('vimage: file format -- BMP, little endian')
					read_bmp(data)
				}
				else {
					return Image{}, ImageOptions(PngOptions{})
				}
			}
		}
	}
}

pub fn write_to_file(image Image, image_options ImageOptions, filename string) ! {
	data := write_to_array(image, image_options)
	return os.write_file_array(filename, data)
}

pub fn write_to_array(image Image, image_options ImageOptions) []u8 {
	return match image_options {
		PngOptions {
			write_png(image, image_options)
		}
		GimOptions {
			write_gim(image, image_options)
		}
		FarbfeldOptions {
			write_farbfeld(image, image_options)
		}
		BmpOptions {
			write_bmp(image, image_options)
		}
	}
}
