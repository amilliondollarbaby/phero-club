// merge <full-image> <crop-x> <crop-y> <crop-w> <crop-h> <out.png>
// Cuts out all subjects of the full image, separately cuts out the subject inside the crop box,
// layers both at original positions, and trims to content.
import Foundation; import Vision; import CoreImage
let a = CommandLine.arguments
let src = CIImage(contentsOf: URL(fileURLWithPath: a[1]))!
let H = src.extent.height
let cx = Double(a[2])!, cy = Double(a[3])!, cw = Double(a[4])!, ch = Double(a[5])!
func mask(_ img: CIImage) throws -> CIImage {
  let h = VNImageRequestHandler(ciImage: img); let r = VNGenerateForegroundInstanceMaskRequest(); try h.perform([r])
  let o = r.results!.first!
  return CIImage(cvPixelBuffer: try o.generateMaskedImage(ofInstances: o.allInstances, from: h, croppedToInstancesExtent: false))
}
let base = try mask(src)
// CI origin is bottom-left
let rect = CGRect(x: cx, y: H - cy - ch, width: cw, height: ch)
let crop = src.cropped(to: rect).transformed(by: CGAffineTransform(translationX: -rect.minX, y: -rect.minY))
let piece = try mask(crop).transformed(by: CGAffineTransform(translationX: rect.minX, y: rect.minY))
let out = piece.composited(over: base)
// trim to alpha bounds
let ctx = CIContext(); let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let cg = ctx.createCGImage(out, from: src.extent, format: .RGBA8, colorSpace: cs)!
let w = cg.width, h = cg.height; var px = [UInt8](repeating: 0, count: w*h*4)
let bc = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
bc.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
var minX = w, minY = h, maxX = 0, maxY = 0
for y in 0..<h { for x in 0..<w where px[(y*w+x)*4+3] > 8 { minX = min(minX,x); maxX = max(maxX,x); minY = min(minY,y); maxY = max(maxY,y) } }
let trimmed = cg.cropping(to: CGRect(x: minX, y: minY, width: maxX-minX+1, height: maxY-minY+1))!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[6]) as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, trimmed, nil); CGImageDestinationFinalize(dest)
print("\(a[6]) \(trimmed.width)x\(trimmed.height)")
