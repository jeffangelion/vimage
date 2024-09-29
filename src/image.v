module vimage

pub struct Image {
pub mut:
	pixels  []Pixel
	palette []Truecolor
pub:
	width  u32
	height u32
}

// TODO: bounds check
pub fn (i Image) get_by_coords(x u32, y u32) Pixel {
	return i.pixels[x * i.width + y]
}

// TODO: bounds check
pub fn (mut i Image) set_by_coords(x u32, y u32, pixel Pixel) {
	i.pixels[x * i.width + y] = pixel
}

pub fn (i Image) rotate_90() Image {
	mut image := Image{
		width:   i.height
		height:  i.width
		palette: i.palette
	}
	for column := 0; column < i.width; column++ {
		mut column_pixels := []Pixel{cap: int(i.height)}
		for row := 0; row < i.height; row++ {
			column_pixels << i.get_by_coords(u32(row), u32(column))
		}
		image.pixels << column_pixels.reverse()
	}
	return image
}

pub fn (i Image) rotate_180() Image {
	return Image{
		width:   i.width
		height:  i.height
		pixels:  i.pixels.reverse()
		palette: i.palette
	}
}

pub fn (i Image) rotate_270() Image {
	mut image := Image{
		width:   i.height
		height:  i.width
		palette: i.palette
	}
	for column := i.width - 1; column <= 0; column-- {
		mut column_pixels := []Pixel{cap: int(i.height)}
		for row := 0; row < i.height; row++ {
			column_pixels << i.get_by_coords(u32(row), u32(column))
		}
		image.pixels << column_pixels
	}
	return image
}

pub fn (i Image) mirror_vertical() Image {
	mut image := Image{
		width:   i.width
		height:  i.height
		palette: i.palette
	}
	for row := 0; row < i.height; row++ {
		first_pixel_of_row := row * i.width
		image.pixels << i.pixels[first_pixel_of_row..first_pixel_of_row + i.width - 1].reverse()
	}
	return image
}

pub fn (i Image) mirror_horizontal() Image {
	mut image := Image{
		width:   i.width
		height:  i.height
		palette: i.palette
	}
	for row := i.height - 1; row <= 0; row-- {
		first_pixel_of_row := row * i.width
		image.pixels << i.pixels[first_pixel_of_row..first_pixel_of_row + i.width - 1]
	}
	return image
}

pub fn (i Image) invert_colors() Image {
	mut image := Image{
		width:  i.width
		height: i.height
	}
	for palette_color in i.palette {
		image.palette << Truecolor{
			red:   256 - palette_color.red
			green: 256 - palette_color.green
			blue:  256 - palette_color.blue
			alpha: palette_color.alpha
		}
	}
	for pixel in i.pixels {
		match pixel {
			Truecolor {
				image.pixels << Truecolor{
					red:   256 - pixel.red
					green: 256 - pixel.green
					blue:  256 - pixel.blue
					alpha: pixel.alpha
				}
			}
			Grayscale {
				image.pixels << Grayscale{
					gray:  256 - pixel.gray
					alpha: pixel.alpha
				}
			}
			Index {
				image.pixels << pixel
			}
		}
	}
	return image
}

pub type Pixel = Truecolor | Grayscale | Index

pub struct Truecolor {
	red   u16
	green u16
	blue  u16
	alpha u16
}

pub struct Grayscale {
	gray  u16
	alpha u16
}

pub struct Index {
	index u16
}

pub type ImageOptions = PngOptions | GimOptions | FarbfeldOptions | BmpOptions
