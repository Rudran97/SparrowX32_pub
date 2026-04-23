#!/usr/bin/env python3

import os
import sys

if len(sys.argv) != 6:
    print("Usage:")
    print("  makehex.py <file.hex> <rom_base> <rom_words> <ram_base> <ram_words>")
    sys.exit(1)

hexfile   = sys.argv[1]
rom_base  = int(sys.argv[2], 0)
rom_words = int(sys.argv[3])
ram_base  = int(sys.argv[4], 0)
ram_words = int(sys.argv[5])

print(f"[INFO] Reading HEX file: {hexfile}")
print(f"[INFO] ROM base=0x{rom_base:08x}, words={rom_words}")
print(f"[INFO] RAM base=0x{ram_base:08x}, words={ram_words}")

mem = {}
upper = 0
lines = 0
data_bytes = 0

with open(hexfile, "r") as f:
    for line in f:
        line = line.strip()
        if not line or line[0] != ":":
            continue

        lines += 1

        ll    = int(line[1:3], 16)
        addr  = int(line[3:7], 16)
        rtype = int(line[7:9], 16)
        data  = line[9:9 + ll * 2]

        if rtype == 0x00:  # data record
            base = upper + addr
            for i in range(ll):
                mem[base + i] = int(data[2*i:2*i+2], 16)
                data_bytes += 1

        elif rtype == 0x04:  # extended linear address
            upper = int(data, 16) << 16

        elif rtype == 0x01:  # EOF
            break

print(f"[INFO] Parsed {lines} HEX records")
print(f"[INFO] Loaded {data_bytes} data bytes")

def dump_region(base, nwords, filename):
    print(f"[INFO] Writing {filename}")
    with open(filename, "w") as f:
        for i in range(nwords):
            addr = base + i*4
            b0 = mem.get(addr + 0, 0)
            b1 = mem.get(addr + 1, 0)
            b2 = mem.get(addr + 2, 0)
            b3 = mem.get(addr + 3, 0)
            f.write(f"{b3:02x}{b2:02x}{b1:02x}{b0:02x}\n")

dump_region(rom_base, rom_words, os.path.join(os.path.dirname(hexfile), "rom.txt"))
dump_region(ram_base, ram_words, os.path.join(os.path.dirname(hexfile), "ram.txt"))

print("[INFO] Done.")