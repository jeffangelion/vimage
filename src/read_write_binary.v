module vimage

import encoding.binary

const big_endian = true

fn read_u16(data []u8, is_big_endian bool) u16 {
	return match is_big_endian {
		true { binary.big_endian_u16(data) }
		false { binary.little_endian_u16(data) }
	}
}

fn write_u16(value u16, is_big_endian bool) []u8 {
	return match is_big_endian {
		true { binary.big_endian_get_u16(value) }
		false { binary.little_endian_get_u16(value) }
	}
}

fn read_u32(data []u8, is_big_endian bool) u32 {
	return match is_big_endian {
		true { binary.big_endian_u32(data) }
		false { binary.little_endian_u32(data) }
	}
}

fn write_u32(value u32, is_big_endian bool) []u8 {
	return match is_big_endian {
		true { binary.big_endian_get_u32(value) }
		false { binary.little_endian_get_u32(value) }
	}
}
