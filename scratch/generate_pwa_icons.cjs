const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

// Pure Node.js PNG encoder
function createPNG(width, height, getPixelRGBA) {
  // Signature
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR chunk
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr.writeUInt8(8, 8); // bit depth 8
  ihdr.writeUInt8(6, 9); // color type 6 (RGBA)
  ihdr.writeUInt8(0, 10); // compression method 0
  ihdr.writeUInt8(0, 11); // filter method 0
  ihdr.writeUInt8(0, 12); // interlace method 0
  const ihdrChunk = makeChunk("IHDR", ihdr);

  // Raw image data with filter byte 0 per scanline
  const scanlineLength = width * 4 + 1;
  const rawData = Buffer.alloc(height * scanlineLength);

  for (let y = 0; y < height; y++) {
    const rowOffset = y * scanlineLength;
    rawData[rowOffset] = 0; // Filter None
    for (let x = 0; x < width; x++) {
      const pixelOffset = rowOffset + 1 + x * 4;
      const [r, g, b, a] = getPixelRGBA(x, y, width, height);
      rawData[pixelOffset] = r;
      rawData[pixelOffset + 1] = g;
      rawData[pixelOffset + 2] = b;
      rawData[pixelOffset + 3] = a;
    }
  }

  // Compress with zlib
  const compressed = zlib.deflateSync(rawData);
  const idatChunk = makeChunk("IDAT", compressed);
  const iendChunk = makeChunk("IEND", Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

function makeChunk(type, data) {
  const length = data.length;
  const chunk = Buffer.alloc(8 + length + 4);
  chunk.writeUInt32BE(length, 0);
  chunk.write(type, 4, 4, "ascii");
  data.copy(chunk, 8);

  const crc = crc32(chunk.subarray(4, 8 + length));
  chunk.writeInt32BE(crc, 8 + length);
  return chunk;
}

// CRC32 table & calculation
const crcTable = new Int32Array(256);
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) {
    c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  crcTable[n] = c;
}

function crc32(buf) {
  let crc = -1;
  for (let i = 0; i < buf.length; i++) {
    crc = crcTable[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return crc ^ -1;
}

// Pixel shader for Pechino Express Bra icon
function renderPechinoIconPixel(x, y, width, height, isMaskable = false) {
  const nx = (x / width) * 2 - 1; // -1 to 1
  const ny = (y / height) * 2 - 1; // -1 to 1
  const dist = Math.sqrt(nx * nx + ny * ny);

  // Background rounded rect / square
  let bgR = 15, bgG = 23, bgB = 42; // #0f172a
  const gradT = (nx + ny + 2) / 4; // 0 to 1
  bgR = Math.round(15 * (1 - gradT) + 49 * gradT);
  bgG = Math.round(23 * (1 - gradT) + 16 * gradT);
  bgB = Math.round(42 * (1 - gradT) + 6 * gradT);

  if (!isMaskable) {
    // Round corners: rx = 0.25 in normalized coords
    const cornerX = Math.max(0, Math.abs(nx) - 0.75);
    const cornerY = Math.max(0, Math.abs(ny) - 0.75);
    const cornerDist = Math.sqrt(cornerX * cornerX + cornerY * cornerY);
    if (cornerDist > 0.25) {
      return [0, 0, 0, 0]; // Transparent outside rounded corner
    }
  }

  // Compass outer ring (radius 0.75 to 0.77)
  if (dist >= 0.72 && dist <= 0.76) {
    return [234, 179, 8, 255]; // Gold #eab308
  }
  if (dist >= 0.65 && dist <= 0.67) {
    const angle = Math.atan2(ny, nx);
    if (Math.sin(angle * 16) > 0) {
      return [255, 255, 255, 180]; // Dashed white circle
    }
  }

  // Cardinal pointers (N, S, E, W)
  const isNorth = ny < -0.65 && Math.abs(nx) < (0.85 + ny) * 0.4;
  const isSouth = ny > 0.65 && Math.abs(nx) < (0.85 - ny) * 0.4;
  const isWest = nx < -0.65 && Math.abs(ny) < (0.85 + nx) * 0.4;
  const isEast = nx > 0.65 && Math.abs(ny) < (0.85 - nx) * 0.4;

  if (isNorth || isSouth || isEast || isWest) {
    return [234, 179, 8, 255]; // Gold pointers
  }

  // Center Compass Needle (Vertical Diamond)
  const absNx = Math.abs(nx);
  // North Needle (Orange/Red)
  if (ny < 0 && ny > -0.55 && absNx < (-ny) * 0.35) {
    if (nx > 0) return [249, 115, 22, 255]; // Orange #f97316
    return [251, 146, 60, 255]; // Light orange #fb923c
  }
  // South Needle (Dark Slate)
  if (ny >= 0 && ny < 0.55 && absNx < (0.55 - ny) * 0.35) {
    if (nx > 0) return [71, 85, 105, 255]; // Slate #475569
    return [51, 65, 85, 255]; // Dark slate #334155
  }

  // Center Hub
  if (dist <= 0.12) {
    if (dist <= 0.05) return [249, 115, 22, 255]; // Orange center dot
    return [15, 23, 42, 255]; // Dark ring
  }
  if (dist <= 0.14) {
    return [234, 179, 8, 255]; // Gold hub border
  }

  return [bgR, bgG, bgB, 255];
}

const iconsDir = path.resolve(__dirname, "../public/icons");
if (!fs.existsSync(iconsDir)) fs.mkdirSync(iconsDir, { recursive: true });

// 1. Generate icon-192.png
const png192 = createPNG(192, 192, (x, y, w, h) => renderPechinoIconPixel(x, y, w, h, false));
fs.writeFileSync(path.join(iconsDir, "icon-192.png"), png192);
console.log("✓ Generated public/icons/icon-192.png (192x192)");

// 2. Generate icon-512.png
const png512 = createPNG(512, 512, (x, y, w, h) => renderPechinoIconPixel(x, y, w, h, false));
fs.writeFileSync(path.join(iconsDir, "icon-512.png"), png512);
console.log("✓ Generated public/icons/icon-512.png (512x512)");

// 3. Generate icon-maskable-512.png
const pngMaskable512 = createPNG(512, 512, (x, y, w, h) => renderPechinoIconPixel(x, y, w, h, true));
fs.writeFileSync(path.join(iconsDir, "icon-maskable-512.png"), pngMaskable512);
console.log("✓ Generated public/icons/icon-maskable-512.png (512x512 maskable)");
