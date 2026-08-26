/**
 * Utility to process and transform image files (flip horizontal, rotate)
 * directly in the browser using HTML Canvas before uploading.
 */

export async function transformImageFile(
  file: File,
  flipH: boolean = false,
  rotationDegrees: number = 0
): Promise<File> {
  const normalizedRotation = ((rotationDegrees % 360) + 360) % 360;
  if (!flipH && normalizedRotation === 0) {
    return file;
  }

  return new Promise((resolve) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(url);
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        resolve(file);
        return;
      }

      const is90or270 = normalizedRotation === 90 || normalizedRotation === 270;
      canvas.width = is90or270 ? img.naturalHeight : img.naturalWidth;
      canvas.height = is90or270 ? img.naturalWidth : img.naturalHeight;

      ctx.save();
      ctx.translate(canvas.width / 2, canvas.height / 2);
      ctx.rotate((normalizedRotation * Math.PI) / 180);
      if (flipH) {
        ctx.scale(-1, 1);
      }
      ctx.drawImage(img, -img.naturalWidth / 2, -img.naturalHeight / 2);
      ctx.restore();

      canvas.toBlob(
        (blob) => {
          if (!blob) {
            resolve(file);
            return;
          }
          const newFile = new File([blob], file.name, {
            type: file.type || "image/jpeg",
            lastModified: Date.now(),
          });
          resolve(newFile);
        },
        file.type || "image/jpeg",
        0.92
      );
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve(file);
    };
    img.src = url;
  });
}
