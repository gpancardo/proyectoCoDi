from collections import Counter, defaultdict
from pathlib import Path
import struct
import zlib


ROOT = Path(__file__).resolve().parents[1]
APP_SEALS = ROOT / 'assets' / 'sellos'
WEB_SEALS = ROOT.parent / 'web' / 'sellos'


def decode_rgba(path):
    blob = path.read_bytes()
    assert blob[:8] == b'\x89PNG\r\n\x1a\n'
    pos, compressed = 8, []
    width = height = bit_depth = color_type = None
    while pos < len(blob):
        length = struct.unpack('>I', blob[pos:pos + 4])[0]
        kind = blob[pos + 4:pos + 8]
        data = blob[pos + 8:pos + 8 + length]
        pos += length + 12
        if kind == b'IHDR':
            width, height, bit_depth, color_type, comp, filt, interlace = struct.unpack('>IIBBBBB', data)
            assert (bit_depth, color_type, comp, filt, interlace) == (8, 6, 0, 0, 0)
        elif kind == b'IDAT':
            compressed.append(data)
        elif kind == b'IEND':
            break

    stride, bpp = width * 4, 4
    raw = zlib.decompress(b''.join(compressed))
    rows, prev, offset = [], bytearray(stride), 0
    for _ in range(height):
        filter_type = raw[offset]
        encoded = raw[offset + 1:offset + 1 + stride]
        offset += stride + 1
        row = bytearray(stride)
        for i, value in enumerate(encoded):
            left = row[i - bpp] if i >= bpp else 0
            up = prev[i]
            upper_left = prev[i - bpp] if i >= bpp else 0
            if filter_type == 1:
                value += left
            elif filter_type == 2:
                value += up
            elif filter_type == 3:
                value += (left + up) // 2
            elif filter_type == 4:
                predictor = left + up - upper_left
                pa, pb, pc = abs(predictor - left), abs(predictor - up), abs(predictor - upper_left)
                value += left if pa <= pb and pa <= pc else up if pb <= pc else upper_left
            elif filter_type != 0:
                raise ValueError(f'PNG filter {filter_type} no compatible')
            row[i] = value & 255
        rows.append(row)
        prev = row
    return width, height, rows


def simplify(points, tolerance=1.0):
    if len(points) <= 3:
        return points
    a, b = points[0], points[-1]
    dx, dy = b[0] - a[0], b[1] - a[1]
    denom = dx * dx + dy * dy
    best_distance, best = -1, 0
    for index, point in enumerate(points[1:-1], 1):
        if denom:
            t = max(0, min(1, ((point[0] - a[0]) * dx + (point[1] - a[1]) * dy) / denom))
            px, py = a[0] + t * dx, a[1] + t * dy
        else:
            px, py = a
        distance = (point[0] - px) ** 2 + (point[1] - py) ** 2
        if distance > best_distance:
            best_distance, best = distance, index
    if best_distance <= tolerance * tolerance:
        return [a, b]
    left = simplify(points[:best + 1], tolerance)
    right = simplify(points[best:], tolerance)
    return left[:-1] + right


def simplify_closed(points):
    anchor = points[0]
    far = max(range(1, len(points)), key=lambda i: (points[i][0] - anchor[0]) ** 2 + (points[i][1] - anchor[1]) ** 2)
    first = simplify(points[:far + 1])
    second = simplify(points[far:] + [anchor])
    return first[:-1] + second[:-1]


def trace(path):
    width, height, rows = decode_rgba(path)
    solid = [[rows[y][x * 4 + 3] >= 128 for x in range(width)] for y in range(height)]
    colors = Counter(tuple(rows[y][x * 4:x * 4 + 3]) for y in range(height) for x in range(width) if rows[y][x * 4 + 3] >= 240)
    r, g, b = colors.most_common(1)[0][0]
    fill = f'#{r:02x}{g:02x}{b:02x}'
    edges = set()
    outgoing = defaultdict(list)
    def add(start, end):
        edge = (start, end)
        edges.add(edge)
        outgoing[start].append(edge)
    for y in range(height):
        for x in range(width):
            if not solid[y][x]:
                continue
            if y == 0 or not solid[y - 1][x]: add((x, y), (x + 1, y))
            if x == width - 1 or not solid[y][x + 1]: add((x + 1, y), (x + 1, y + 1))
            if y == height - 1 or not solid[y + 1][x]: add((x + 1, y + 1), (x, y + 1))
            if x == 0 or not solid[y][x - 1]: add((x, y + 1), (x, y))

    loops = []
    while edges:
        edge = min(edges)
        start, current = edge
        loop = [start]
        previous = start
        edges.remove(edge)
        while current != start:
            loop.append(current)
            candidates = [item for item in outgoing[current] if item in edges]
            if not candidates:
                break
            dx, dy = current[0] - previous[0], current[1] - previous[1]
            direction = {(1, 0): 0, (0, 1): 1, (-1, 0): 2, (0, -1): 3}[(dx, dy)]
            def turn(item):
                nxt = item[1]
                out_dir = {(1, 0): 0, (0, 1): 1, (-1, 0): 2, (0, -1): 3}[(nxt[0] - current[0], nxt[1] - current[1])]
                return {1: 0, 0: 1, 3: 2, 2: 3}[(out_dir - direction) % 4]
            next_edge = min(candidates, key=turn)
            edges.remove(next_edge)
            previous, current = next_edge
        if len(loop) >= 3 and current == start:
            loop = simplify_closed(loop)
            loops.append(loop)
    path_data = []
    for loop in loops:
        if len(loop) < 3:
            continue
        path_data.append('M' + ' L'.join(f'{x} {y}' for x, y in loop) + ' Z')
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img"><path fill="{fill}" fill-rule="evenodd" d="{" ".join(path_data)}"/></svg>\n'


converted = 0
for output in sorted(APP_SEALS.glob('*.png')):
    source = WEB_SEALS / output.name
    if not source.exists():
        source = output
    svg = trace(source)
    (APP_SEALS / f'{output.stem}.svg').write_text(svg, encoding='utf-8')
    converted += 1
print(f'Convertidos {converted} sellos desde PNG a SVG.')
