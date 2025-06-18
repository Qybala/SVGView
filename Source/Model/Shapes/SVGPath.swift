import SwiftUI
import Combine

public class SVGPath: SVGShape, ObservableObject {

    @Published public var segments: [PathSegment]
    @Published public var fillRule: CGPathFillRule

    public init(segments: [PathSegment] = [], fillRule: CGPathFillRule = .winding) {
        self.segments = segments
        self.fillRule = fillRule
    }

    override public func frame() -> CGRect {
        toBezierPath().cgPath.boundingBoxOfPath
    }

    override public func bounds() -> CGRect {
        frame()
    }

    override func serialize(_ serializer: Serializer) {
        let path = segments.map { s in "\(s.type)\(s.data.compactMap { $0.serialize() }.joined(separator: ","))" }.joined(separator: " ")
        serializer.add("path", path)
        serializer.add("fillRule", fillRule)
        super.serialize(serializer)
    }

    public func contentView() -> some View {
        SVGPathView(model: self)
    }
}

struct SVGPathView: View {

    @ObservedObject var model = SVGPath()

    public var body: some View {
        GeometryReader { proxy in
            let frame = self.model.frame()
            model.toBezierPath().toSwiftUI(model: model, eoFill: model.fillRule == .evenOdd)
            // .background(Rectangle().stroke(.purple, lineWidth: 1))
//                .onAppear() {
//                    print("SVGPathView - \(proxy.size); \(self.model.id) - purple with frame \(self.model.frame())")
//                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension MBezierPath {

    func toSwiftUI(model: SVGShape, eoFill: Bool = false) -> some View {
        let isGradient = model.fill is SVGGradient
        let bounds = isGradient ? model.bounds() : CGRect.zero
        return Path(self.cgPath)
            .applySVGStroke(stroke: model.stroke, eoFill: eoFill)
            .applyShapeAttributes(model: model)
            .applyIf(isGradient) {
                $0.frame(width: bounds.width, height: bounds.height)
                    .position(x: 0, y: 0)
                    .offset(x: bounds.width/2, y: bounds.height/2)
            }
    }
}

