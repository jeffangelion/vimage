module vimage

import log

const gim_big_endian_signature = [u8(0x2E), 0x47, 0x49, 0x4D, 0x31, 0x2E, 0x30, 0x30]
const gim_little_endian_signature = [u8(0x4D), 0x49, 0x47, 0x2E, 0x30, 0x30, 0x2E, 0x31]

pub struct GimOptions {}

fn read_gim(data []u8) (?Image, ?ImageOptions) {
	log.info('vimage: GIM: work in progress')
	image := Image{}
	image_options := ImageOptions{}
	return image, image_options
}

fn write_gim(image Image, image_options ImageOptions) []u8 {
	log.info('vimage: GIM: work in progress')
	return []u8{}
}
