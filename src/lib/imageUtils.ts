/**
 * Utility to process and transform image files (flip horizontal, rotate, resize)
 * directly in the browser using HTML Canvas before uploading.
 */

export async function transformImageFile(
  file: File,
  flipH: boolean = false,
  rotationDegrees: number = 0,
  maxDimension: number = 2048
): Promise<File> {
  const normalizedRotation = ((rotationDegrees % 360) + 360) % 360;

  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => {
      const img = new Image();
      img.onload = () => {
        try {
          const canvas = document.createElement("canvas");
          const ctx = canvas.getContext("2d");
          if (!ctx) {
            resolve(file);
            return;
          }

          // Calculate scaled dimensions to preserve memory and high quality
          let width = img.naturalWidth || img.width;
          let height = img.naturalHeight || img.height;

          if (width > maxDimension || height > maxDimension) {
            if (width > height) {
              height = Math.round((height * maxDimension) / width);
              width = maxDimension;
            } else {
              width = Math.round((width * maxDimension) / height);
              height = maxDimension;
            }
          }

          const is90or270 = normalizedRotation === 90 || normalizedRotation === 270;
          canvas.width = is90or270 ? height : width;
          canvas.height = is90or270 ? width : height;

          ctx.imageSmoothingEnabled = true;
          ctx.imageSmoothingQuality = "high";

          ctx.save();
          ctx.translate(canvas.width / 2, canvas.height / 2);
          ctx.rotate((normalizedRotation * Math.PI) / 180);
          if (flipH) {
            ctx.scale(-1, 1);
          }
          ctx.drawImage(img, -width / 2, -height / 2, width, height);
          ctx.restore();

          if (canvas.toBlob) {
            canvas.toBlob(
              (blob) => {
                if (!blob) {
                  resolve(fallbackDataUrlToFile(canvas, file));
                  return;
                }
                const newFile = new File([blob], file.name, {
                  type: "image/jpeg",
                  lastModified: Date.now(),
                });
                resolve(newFile);
              },
              "image/jpeg",
              0.92
            );
          } else {
            resolve(fallbackDataUrlToFile(canvas, file));
          }
        } catch (err) {
          console.error("Image transform error:", err);
          resolve(file);
        }
      };
      img.onerror = () => resolve(file);
      img.src = reader.result as string;
    };
    reader.onerror = () => resolve(file);
    reader.readAsDataURL(file);
  });
}

function fallbackDataUrlToFile(canvas: HTMLCanvasElement, originalFile: File): File {
  try {
    const dataUrl = canvas.toDataURL("image/jpeg", 0.92);
    const parts = dataUrl.split(",");
    if (parts.length < 2 || !parts[0] || !parts[1]) {
      return originalFile;
    }
    const mimeMatch = parts[0].match(/:(.*?);/);
    const mime = (mimeMatch && mimeMatch[1]) ? mimeMatch[1] : "image/jpeg";
    const bstr = atob(parts[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) {
      u8arr[n] = bstr.charCodeAt(n);
    }
    return new File([u8arr], originalFile.name, { type: mime, lastModified: Date.now() });
  } catch {
    return originalFile;
  }
}
