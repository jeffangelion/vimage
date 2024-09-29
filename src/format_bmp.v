module vimage

import log

const bmp_big_endian_signature = [u8(0x42), 0x4D]
const bmp_little_endian_signature = [u8(0x4D), 0x42]

pub struct BmpOptions {}

fn read_bmp(data []u8) (?Image, ?ImageOptions) {
	log.info('vimage: BMP: work in progress')
	image := Image{}
	image_options := ImageOptions{}
	return image, image_options
}

fn write_bmp(image Image, image_options ImageOptions) []u8 {
	log.info('vimage: BMP: work in progress')
	return []u8{}
}
