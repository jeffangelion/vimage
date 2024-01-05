import math

pub struct Image {
	compression_method u8 = 0 // zlib
	filter_method      u8 = 0 // adaptive filtering with five basic filter types
pub:
	width              u32
	height             u32
	interlace_method   u8
	color_type         ColorType
	bit_depth          u8
pub mut:
	pixels             []Pixel
	palette            []TrueColor
}

pub type Pixel = Grayscale | TrueColor | Indexed | GrayscaleAlpha | TrueColorAlpha

pub struct Grayscale {
pub mut:
	gray u8
}

pub struct TrueColor {
pub mut:
	red   u8
	green u8
	blue  u8
}

pub struct Indexed {
pub mut:
	index u8
}

pub struct GrayscaleAlpha {
pub mut:
	gray  u8
	alpha u8
}

pub struct TrueColorAlpha {
pub mut:
	red   u8
	green u8
	blue  u8
	alpha u8
}

pub enum ColorType as u8 {
	grayscale       = 0
	truecolor       = 2
	indexed         = 3
	grayscale_alpha = 4
	truecolor_alpha = 6
	@none           = 255
}

[noinit]
struct IDATChunks {
pub:
	filtered   []u8 [required]
	bpp        int  [required]
	stride     int  [required]
pub mut:
	defiltered []u8
}

fn (i IDATChunks) defilter_sub(row int, column int) u8 {
	return i.filtered[row * idat_chunks.stride + column] + if column >= i.bpp {
		i.defiltered[row * i.stride + column - i.bpp]
	} else {
		0
	}
}

fn (i IDATChunks) defilter_up(row int, column int) u8 {
	return i.filtered[row * idat_chunks.stride + column] + if row > 0 {
		i.defiltered[(row - 1) * i.stride + column]
	} else {
		0
	}
}

fn (i IDATChunks) defilter_average(row int, column int) u8 {
	return i.filtered[row * idat_chunks.stride + column] + math.floor((i.defilter_sub(row, column) + i.defilter_up(row, column)) / 2)
}

// Wrapper for Prior(x-bpp) in PaethPredictor function
fn (i IDATChunks) _defilter_up_minus_bpp(row int, column int) u8 {
	return if column >= i.bpp {
		defilter_up(row, column - i.bpp)
	} else {
		defilter_up(row, column)
	}
}

fn (i IDATChunks) defilter_paeth(row int, column int) u8 {
	a := defilter_sub(row, column)
	b := defilter_up(row, column)
	c := _defilter_up_minus_bpp(row, column)
	p := a + b - c
	pa := math.abs(p - a)
	pb := math.abs(p - b)
	pc := math.abs(p - c)
	return i.filtered[row * idat_chunks.stride + column] + if (pa <= pb && pa <= pc) {
		a
	} else if pb <= pc {
		b
	} else {
		c
	}
}
