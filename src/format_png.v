module vimage

import log

const png_signature = [u8(0x89), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

pub struct PngOptions {}

fn read_png(data []u8) (?Image, ?ImageOptions) {
	log.info('vimage: PNG: work in progress')
	image := Image{}
	image_options := ImageOptions{}
	return image, image_options
}

fn write_png(image Image, image_options ImageOptions) []u8 {
	log.info('vimage: PNG: work in progress')
	return []u8{}
}
