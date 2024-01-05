import os
import hash.crc32
import encoding.binary
import compress.zlib
import math

pub fn read_from_file(filename string) ?Image {
	file_content := os.read_bytes(filename) or {
		return none
	}
	return read_from_array(file_content) or {
		none
	}
}

pub fn read_from_array(content []u8) ?Image {
	if content[ .. 8] != signature {
		return none
	}
	content_without_signature := content[8 .. ]
	// mut is_ihdr_present := false
	// mut is_plte_present := false
	// mut is_idat_present := false
	// mut is_indexed      := false
	/* Temporary variables */
	mut width            := u32(0)
	mut height           := u32(0)
	mut bit_depth        := u8(0)
	mut color_type       := ColorType.@none
	mut interlace_method := u8(0)
	mut palette          := []TrueColor{}
	mut idat_concatenate := []u8
	mut pixels           := []Pixel{}
	/* Temporary variables END */
	/* Read chunks */
	for offset := 0; offset < content_without_signature.len {
		chunk_data_length := binary.big_endian_u32_at(content_without_signature, offset)
		offset += 4 // Skip chunk data length field
		match content_without_signature[offset .. offset + 4] {
			/* Critical chunks */
			iend_chunk[ .. 4] {
				break
			}
			ihdr_header {
				if check_chunk_checksum(content_without_signature[offset .. offset + chunk_data_length + 4]) { // CRC32 checksum is not included in chunk data length
					return none
				}
				offset += 4 // Skip IHDR chunk header
				width            = binary.big_endian_u32_at(content_without_signature, offset)
				height           = binary.big_endian_u32_at(content_without_signature, offset + 4)
				bit_depth        = content_without_signature[offset + 5]
				interlace_method = content_without_signature[offset + 9]
				color_type       = match content_without_signature[offset + 6] {
							0 { .grayscale }
							2 { .truecolor }
							3 { .indexed }
							4 { .grayscale_alpha }
							6 { .truecolor_alpha }
							else {}
				}
			}
			plte_header {
				if check_chunk_checksum(content_without_signature[offset .. offset + chunk_data_length + 4]) { // CRC32 checksum is not included in chunk data length
					return none
				}
				if chunk_data_length % 3 != 0 {
					return none
				}
				offset += 4 // Skip PLTE chunk header
				for color_index := 0; color_index < chunk_data_length; color_index += 3 {
					palette << TrueColor {
						red:   content_without_signature[offset + color_index]
						green: content_without_signature[offset + color_index + 1]
						blue:  content_without_signature[offset + color_index + 2]
					}
				}
			}
			idat_header {
				if check_chunk_checksum(content_without_signature[offset .. offset + chunk_data_length + 4]) { // CRC32 checksum is not included in chunk data length
					return none
				}
				offset += 4 // Skip IDAT chunk header
				idat_concatenate << content_without_signature[offset .. offset + chunk_data_length]
			}
			/* Critical chunks END */
			else {}
		}
		offset += chunk_data_length + 4 // Skip chunk data & chunk checksum
	}
	/* Read chunks END */
	bits_per_pixel := match color_type {
		.grayscale       {
			if (bit_depth == 1) || (bit_depth == 2) || (bit_depth == 4) || (bit_depth == 8) || (bit_depth == 16) {
				1 * bit_depth
			} else {
				return none
			}
		}
		.truecolor       {
			if (bit_depth == 8) || (bit_depth == 16) {
				3 * bit_depth
			} else {
				return none
			}
		}
		.indexed         {
			if (bit_depth == 1) || (bit_depth == 2) || (bit_depth == 4) || (bit_depth == 8) {
				1 * bit_depth
			} else {
				return none
			}
		}
		.grayscale_alpha {
			if (bit_depth == 8) || (bit_depth == 16) {
				2 * bit_depth
			} else {
				return none
			}
		}
		.truecolor_alpha {
			if (bit_depth == 8) || (bit_depth == 16) {
				4 * bit_depth
			} else {
				return none
			}
		}
	}
	bytes_per_pixel := math.ceil(bits_per_pixel / 8)
	bytes_per_scanline := width * bytes_per_pixel // TODO: check if it works with 1-4 bit depth
	mut idat_chunks := IDATChunks {
		filtered: zlib.decompress(idat_concatenate) or {
			return none
		}
		bpp: bytes_per_pixel
		stride: bytes_per_scanline
	}
	/* Defilter IDAT chunks */
	for row in 0 .. height {
		filter_type := idat_chunks.decompressed[row * idat_chunks.stride] // First byte of each scanline defines filter type
		for column in 1 .. idat_chunks.stride {
			idat_chunks.defiltered << match filter_type {
				// None
				0 { idat_chunks.decompressed[row * idat_chunks.stride + column] }
				// Sub
				1 { idat_chunks.defilter_sub(row, column) }
				// Up
				2 { idat_chunks.defilter_up(row, column) }
				// Average
				3 { idat_chunks.defilter_average(row, column) }
				// Paeth
				4 { idat_chunks.defilter_paeth(row, column) }
				else {}
			}
		}
	}
	/* Defilter IDAT chunks END */
	/* Read pixels from defiltered IDAT chunks */
	for index := 0; index < idat_chunks.defiltered.len; i += idat_chunks.bpp {
		pixels << match color_type {
			.grayscale {
				Pixel(Grayscale {
					gray:
				})
			}
			.truecolor {
				Pixel(TrueColor {
					red:
					green:
					blue:
				})
			}
			.indexed {
				Pixel(Indexed {
					index:
				})
			}
			.grayscale_alpha {
				Pixel(GrayscaleAlpha {
					gray:
					alpha:
				})
			}
			.truecolor_alpha {
				Pixel(TrueColorAlpha {
					red:
					green:
					blue:
					alpha:
				})
			}
			else {}
		}
	}
	/* Read pixels from defiltered IDAT chunks END */
	/* Read PLTE chunk (if present) */
	/* Read PLTE chunk (if present) END */
}

fn check_chunk_checksum(chunk []u8) bool {
	checksum := binary.big_endian_u32_at(chunk, chunk.len - 4) // CRC32 checksum is last 4 bytes of chunk
	return (crc32.sum(chunk[4 .. chunk.len - 4]) == checksum)  // Chunk header is first 4 bytes of chunk
}

fn defilter_prior() {}

pub fn write_to_file(image Image, filename string) bool {
	file_content := write_to_array(image) or {
		return false
	}
	file := os.create(filename) or {
		return false
	}
	bytes_written := file.write(file_content) or {
		return false
	}
	return (bytes_written == file_content.len)
}

pub fn write_to_array(image Image) []u8 {}
