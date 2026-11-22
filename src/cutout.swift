// Local background removal with Apple Vision (no upload).
// usage: cutout <input> <output-prefix> [all|each]
//   all  -> <prefix>.png with every foreground subject, cropped to them
//   each -> <prefix>-1.png, -2.png ... one per subject, largest first (prints sizes)
import Foundation
import Vision
import CoreImage

let a = CommandLine.arguments
guard a.count >= 3 else { print("usage: cutout in out-prefix [all|each]"); exit(1) }
let input = URL(fileURLWithPath: a[1]), prefix = a[2], mode = a.count > 3 ? a[3] : "all"
guard let ci = CIImage(contentsOf: input) else { print("cannot read \(a[1])"); exit(1) }
let handler = VNImageRequestHandler(ciImage: ci)
let req = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([req])
guard let obs = req.results?.first else { print("no subject found"); exit(2) }
let ctx = CIContext()
let cs = CGColorSpace(name: CGColorSpace.sRGB)!

func save(_ inst: IndexSet, _ path: String) throws -> CGSize {
    let buf = try obs.generateMaskedImage(ofInstances: inst, from: handler, croppedToInstancesExtent: true)
    var img = CIImage(cvPixelBuffer: buf)
    img = img.transformed(by: CGAffineTransform(translationX: -img.extent.origin.x, y: -img.extent.origin.y))
    try ctx.writePNGRepresentation(of: img, to: URL(fileURLWithPath: path), format: .RGBA8, colorSpace: cs)
    return img.extent.size
}

if mode == "each" {
    var items: [(Int, CGSize)] = []
    for i in obs.allInstances {
        let tmp = "\(prefix)-tmp\(i).png"
        let s = try save(IndexSet(integer: i), tmp)
        items.append((i, s))
    }
    items.sort { $0.1.width * $0.1.height > $1.1.width * $1.1.height }
    for (n, (i, s)) in items.enumerated() {
        let dst = "\(prefix)-\(n + 1).png"
        try? FileManager.default.removeItem(atPath: dst)
        try FileManager.default.moveItem(atPath: "\(prefix)-tmp\(i).png", toPath: dst)
        print("\(dst) \(Int(s.width))x\(Int(s.height))")
    }
} else {
    let s = try save(obs.allInstances, "\(prefix).png")
    print("\(prefix).png \(Int(s.width))x\(Int(s.height)) instances=\(obs.allInstances.count)")
}
