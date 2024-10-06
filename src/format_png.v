module vimage

import log
import hash.crc32
import compress.zlib
import math

const png_signature = [u8(0x89), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

const png_chunk_header_ihdr = [u8(0x49), 0x48, 0x44, 0x52] // Image header
const png_chunk_header_plte = [u8(0x50), 0x4C, 0x54, 0x45] // Palette
const png_chunk_header_idat = [u8(0x49), 0x44, 0x41, 0x54] // Image data
const png_chunk_header_iend = [u8(0x49), 0x45, 0x4E, 0x44]
const png_chunk_iend = [u8(0x49), 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82] // PNG version 1.2 complaint empty image trailer chunk

pub struct PngOptions {}

enum PngColorType as u8 {
	grayscale       = 0
	truecolor       = 2
	index           = 3
	grayscale_alpha = 4
	truecolor_alpha = 6
}

struct PngIdat {
	bpp    u8
	stride u32
mut:
	filtered []u8
	raw      []u8
}

fn (idat PngIdat) filter_none(row u32, column u32) u8 {
	return idat.raw[row * idat.stride + column]
}

fn (idat PngIdat) defilter_none(row u32, column u32) u8 {
	return idat.filtered[row * idat.stride + column]
}

fn (idat PngIdat) filter_sub(row u32, column u32) u8 {
	return idat.raw[row * idat.stride + column] - match idat.bpp > column {
		true { 0 }
		false { idat.filtered[row * idat.stride + column - idat.bpp] }
	}
}

fn (idat PngIdat) defilter_sub(row u32, column u32) u8 {
	return idat.filtered[row * idat.stride + column] + match idat.bpp > column {
		true { 0 }
		false { idat.raw[row * idat.stride + column - idat.bpp] }
	}
}

fn (idat PngIdat) filter_up(row u32, column u32) u8 {
	return idat.raw[row * idat.stride + column] - match row != 0 {
		true { idat.filtered[(row - 1) * idat.stride + column] }
		false { 0 }
	}
}

fn (idat PngIdat) defilter_up(row u32, column u32) u8 {
	return idat.filtered[row * idat.stride + column] + match row != 0 {
		true { idat.raw[(row - 1) * idat.stride + column] }
		false { 0 }
	}
}

fn (idat PngIdat) filter_average(row u32, column u32) u8 {
	mut png_average := u8(0)
	png_average += match idat.bpp > column {
		true { 0 }
		false { idat.filtered[row * idat.stride + column - idat.bpp] }
	}
	png_average += match row != 0 {
		true { idat.filtered[(row - 1) * idat.stride + column] }
		false { 0 }
	}
	png_average /= 2
	png_average = u8(math.floor(png_average))
	return idat.raw[row * idat.stride + column] - png_average
}

fn (idat PngIdat) defilter_average(row u32, column u32) u8 {
	mut png_average := u8(0)
	png_average += match idat.bpp > column {
		true { 0 }
		false { idat.raw[row * idat.stride + column - idat.bpp] }
	}
	png_average += match row != 0 {
		true { idat.raw[(row - 1) * idat.stride + column] }
		false { 0 }
	}
	png_average /= 2
	png_average = u8(math.floor(png_average))
	return idat.filtered[row * idat.stride + column] + png_average
}

fn (idat PngIdat) filter_paeth(row u32, column u32) u8 {
	png_paeth_a := match idat.bpp > column {
		true { 0 }
		false { idat.filtered[row * idat.stride + column - idat.bpp] }
	}
	png_paeth_b := match row != 0 {
		true { idat.filtered[(row - 1) * idat.stride + column] }
		false { 0 }
	}
	png_paeth_c := match idat.bpp <= column && row != 0 {
		true { idat.filtered[(row - 1) * idat.stride + column - idat.bpp] }
		false { 0 }
	}
	png_paeth_p := png_paeth_a + png_paeth_b - png_paeth_c
	png_paeth_pa := math.abs(png_paeth_p - png_paeth_a)
	png_paeth_pb := math.abs(png_paeth_p - png_paeth_b)
	png_paeth_pc := math.abs(png_paeth_p - png_paeth_c)
	return idat.raw[row * idat.stride + column] - if png_paeth_pa <= png_paeth_pb
		&& png_paeth_pa <= png_paeth_pc {
		png_paeth_a
	} else if png_paeth_pb <= png_paeth_pc {
		png_paeth_b
	} else {
		png_paeth_c
	}
}

fn (idat PngIdat) defilter_paeth(row u32, column u32) u8 {
	png_paeth_a := match idat.bpp > column {
		true { 0 }
		false { idat.raw[row * idat.stride + column - idat.bpp] }
	}
	png_paeth_b := match row != 0 {
		true { idat.raw[(row - 1) * idat.stride + column] }
		false { 0 }
	}
	png_paeth_c := match idat.bpp <= column && row != 0 {
		true { idat.raw[(row - 1) * idat.stride + column - idat.bpp] }
		false { 0 }
	}
	png_paeth_p := png_paeth_a + png_paeth_b - png_paeth_c
	png_paeth_pa := math.abs(png_paeth_p - png_paeth_a)
	png_paeth_pb := math.abs(png_paeth_p - png_paeth_b)
	png_paeth_pc := math.abs(png_paeth_p - png_paeth_c)
	return idat.filtered[row * idat.stride + column] + if png_paeth_pa <= png_paeth_pb && png_paeth_pa <= png_paeth_pc {
		png_paeth_a
	} else if png_paeth_pb <= png_paeth_pc {
		png_paeth_b
	} else {
		png_paeth_c
	}
}

fn read_png(data []u8) (?Image, ?ImageOptions) {
	log.info('vimage: PNG: work in progress')
	mut offset := 8
	mut png_width := u32(0)
	mut png_height := u32(0)
	mut png_bit_depth := u8(0)
	mut png_color_type := PngColorType.grayscale
	mut png_interlace_method := u8(0)
	mut png_palette := []Truecolor{}
	mut png_idat_compressed := []u8{}
	for offset < data.len {
		png_chunk_data_length := read_u32(data[offset..offset + 4], big_endian)
		offset += 4
		match data[offset..offset + 4] {
			png_chunk_header_iend {
				break
			}
			png_chunk_header_ihdr {
				if png_checksum(data[offset..offset + png_chunk_data_length], data[offset +
					png_chunk_data_length..offset + png_chunk_data_length + 4])
				{
					log.error('vimage: PNG: IHDR checksum is incorrect')
				}
				offset += 4
				png_width = read_u32(data[offset..offset + 4], big_endian)
				png_height = read_u32(data[offset + 4..offset + 8], big_endian)
				png_bit_depth = data[offset + 5]
				png_color_type = PngColorType.from(data[offset + 6]) or {
					log.error('vimage: PNG: unknown color type: ${data[offset + 6]}')
					return none, none
				}
				// png_compression_method
				// png_filter_method
				png_interlace_method = data[offset + 9]
			}
			png_chunk_header_plte {
				if png_checksum(data[offset..offset + png_chunk_data_length], data[offset +
					png_chunk_data_length..offset + png_chunk_data_length + 4])
				{
					log.error('vimage: PNG: PLTE checksum is incorrect')
				}
				offset += 4
				if png_chunk_data_length % 3 == 0 {
					for i := 0; i < png_chunk_data_length; i += 3 {
						png_palette << Truecolor{
							red:   data[offset + i]
							green: data[offset + i + 1]
							blue:  data[offset + i + 2]
						}
					}
				} else {
					log.error('vimage: PNG: PLTE chunk length is incorrect')
				}
			}
			png_chunk_header_idat {
				if png_checksum(data[offset..offset + png_chunk_data_length], data[offset +
					png_chunk_data_length..offset + png_chunk_data_length + 4])
				{
					log.error('vimage: PNG: IDAT checksum is incorrect')
				}
				offset += 4
				png_idat_compressed << data[offset..offset + png_chunk_data_length]
			}
			else {}
		}
		offset += png_chunk_data_length + 4
	}
	png_bits_per_pixel := match png_color_type {
		.grayscale {
			if png_bit_depth == 1 || png_bit_depth == 2 || png_bit_depth == 4 || png_bit_depth == 8
				|| png_bit_depth == 16 {
				1 * png_bit_depth
			} else {
				log.error('vimage: PNG: incorrect ${png_color_type.str()} bit depth: ${png_bit_depth}')
				return none, none
			}
		}
		.truecolor {
			if png_bit_depth == 8 || png_bit_depth == 16 {
				3 * png_bit_depth
			} else {
				log.error('vimage: PNG: incorrect ${png_color_type.str()} bit depth: ${png_bit_depth}')
				return none, none
			}
		}
		.index {
			if png_bit_depth == 1 || png_bit_depth == 2 || png_bit_depth == 4 || png_bit_depth == 8 {
				1 * png_bit_depth
			} else {
				log.error('vimage: PNG: incorrect ${png_color_type.str()} bit depth: ${png_bit_depth}')
				return none, none
			}
		}
		.grayscale_alpha {
			if png_bit_depth == 8 || png_bit_depth == 16 {
				2 * png_bit_depth
			} else {
				log.error('vimage: PNG: incorrect ${png_color_type.str()} bit depth: ${png_bit_depth}')
				return none, none
			}
		}
		.truecolor_alpha {
			if png_bit_depth == 8 || png_bit_depth == 16 {
				4 * png_bit_depth
			} else {
				log.error('vimage: PNG: incorrect ${png_color_type.str()} bit depth: ${png_bit_depth}')
				return none, none
			}
		}
	}
	png_bytes_per_pixel := u8(math.ceil(png_bits_per_pixel / 8))
	png_bytes_per_scanline := png_bytes_per_pixel * png_width
	mut png_idat := PngIdat{
		bpp:      png_bytes_per_pixel
		stride:   png_bytes_per_scanline
		filtered: zlib.decompress(png_idat_compressed) or {
			log.error('vimage: PNG: IDAT decompression failed')
			return none, none
		}
	}
	for row in 0 .. png_height {
		png_filter_type := png_idat.filtered[row * png_bytes_per_scanline]
		for column in 1 .. png_bytes_per_scanline {
			png_idat.raw << match png_filter_type {
				0 {
					png_idat.defilter_none(row, column)
				}
				1 {
					png_idat.defilter_sub(row, column)
				}
				2 {
					png_idat.defilter_up(row, column)
				}
				3 {
					png_idat.defilter_average(row, column)
				}
				4 {
					png_idat.defilter_paeth(row, column)
				}
				else {
					return none, none
				}
			}
		}
	}
	if png_interlace_method == 1 {
		log.error('vimage: PNG: Adam7 interlace method is not supported yet')
	}
	mut png_pixels := []Pixel{}
	for index := 0; index < png_idat.raw.len; index += png_idat.bpp {
		png_pixels << match png_bits_per_pixel {
			// TODO: 1/2/4-bit pixel support
			8 {
				match png_color_type {
					.grayscale {
						Pixel(Grayscale{
							gray: png_idat.raw[index]
						})
					}
					.truecolor {
						Pixel(Truecolor{
							red:   png_idat.raw[index]
							green: png_idat.raw[index + 1]
							blue:  png_idat.raw[index + 2]
						})
					}
					.index {
						Pixel(Index{
							index: png_idat.raw[index]
						})
					}
					.grayscale_alpha {
						Pixel(Grayscale{
							gray:  png_idat.raw[index]
							alpha: png_idat.raw[index + 1]
						})
					}
					.truecolor_alpha {
						Pixel(Truecolor{
							red:   png_idat.raw[index]
							green: png_idat.raw[index + 1]
							blue:  png_idat.raw[index + 2]
							alpha: png_idat.raw[index + 3]
						})
					}
				}
			}
			16 {
				match png_color_type {
					.grayscale {
						Pixel(Grayscale{
							gray: read_u16(png_idat.raw[index..index + 2], big_endian)
						})
					}
					.truecolor {
						Pixel(Truecolor{
							red:   read_u16(png_idat.raw[index..index + 2], big_endian)
							green: read_u16(png_idat.raw[index + 2..index + 4], big_endian)
							blue:  read_u16(png_idat.raw[index + 4..index + 6], big_endian)
						})
					}
					.grayscale_alpha {
						Pixel(Grayscale{
							gray:  read_u16(png_idat.raw[index..index + 2], big_endian)
							alpha: read_u16(png_idat.raw[index + 2..index + 4], big_endian)
						})
					}
					.truecolor_alpha {
						Pixel(Truecolor{
							red:   read_u16(png_idat.raw[index..index + 2], big_endian)
							green: read_u16(png_idat.raw[index + 2..index + 4], big_endian)
							blue:  read_u16(png_idat.raw[index + 4..index + 6], big_endian)
							alpha: read_u16(png_idat.raw[index + 6..index + 8], big_endian)
						})
					}
					else {
						log.error('vimage: PNG: incorrect color type for ${png_bit_depth}-bit depth')
						return none, none
					}
				}
			}
			else {
				return none, none
			}
		}
	}
	mut image := Image{
		width:   png_width
		height:  png_height
		pixels:  png_pixels
		palette: png_palette
	}
	image_options := ImageOptions(PngOptions{})
	return image, image_options
}

fn write_png(image Image, image_options ImageOptions) []u8 {
	log.info('vimage: PNG: work in progress')
	return []u8{}
}

fn png_checksum(data []u8, checksum []u8) bool {
	return crc32.sum(data) != read_u32(checksum, big_endian)
}
