"""Read captured PNGs without external packages; reject splash/home captures."""
import argparse
import struct
import zlib
from pathlib import Path


def read_png(path, sample=None):
    data = Path(path).read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('Not a PNG image: ' + str(path))
    offset = 8
    compressed = []
    width = height = channels = None
    ended = False
    while offset < len(data):
        length = struct.unpack_from('>I', data, offset)[0]
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + length]
        crc = struct.unpack_from('>I', data, offset + 8 + length)[0]
        if zlib.crc32(kind + payload) & 0xffffffff != crc:
            raise ValueError('PNG chunk checksum mismatch')
        if kind == b'IHDR':
            width, height, depth, colour, compression, filtering, interlace = struct.unpack('>IIBBBBB', payload)
            if depth != 8 or colour not in (2, 6) or interlace != 0:
                raise ValueError('Unsupported screenshot PNG format')
            channels = 4 if colour == 6 else 3
        if kind == b'IDAT':
            compressed.append(payload)
        offset += length + 12
        if kind == b'IEND':
            ended = True
            break
    if not ended or offset != len(data) or width is None or width < 100 or height < 100:
        raise ValueError('Incomplete screenshot PNG')
    raw = zlib.decompress(b''.join(compressed))
    stride = width * channels + 1
    if len(raw) != height * stride:
        raise ValueError('PNG decoded byte length mismatch')
    pixel = None
    if sample is not None:
        x, y = sample(width, height)
        count = (x + 1) * channels
        previous = bytearray(count)
        for row_index in range(y + 1):
            start = row_index * stride
            method = raw[start]
            row = bytearray(raw[start + 1:start + 1 + count])
            for column in range(count):
                left = row[column - channels] if column >= channels else 0
                up = previous[column]
                upper_left = previous[column - channels] if column >= channels else 0
                if method == 0:
                    predictor = 0
                elif method == 1:
                    predictor = left
                elif method == 2:
                    predictor = up
                elif method == 3:
                    predictor = (left + up) // 2
                elif method == 4:
                    p = left + up - upper_left
                    distances = [abs(p - left), abs(p - up), abs(p - upper_left)]
                    predictor = [left, up, upper_left][distances.index(min(distances))]
                else:
                    raise ValueError('Invalid PNG row filter')
                row[column] = (row[column] + predictor) & 255
            previous = row
        pixel = tuple(previous[x * channels:x * channels + 3])
    return width, height, pixel


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--require-app-header', action='store_true')
    parser.add_argument('paths', nargs='+')
    args = parser.parse_args()
    for path in args.paths:
        sample = (lambda width, height: (10, int(height * .08))) if args.require_app_header else None
        width, height, pixel = read_png(path, sample)
        if pixel is not None and pixel != (21, 51, 92):
            raise ValueError('App header is not displayed yet: ' + str(pixel))
        print(f'PASS PNG: {Path(path).name}, {width}x{height}, header={pixel}')
