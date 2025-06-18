import Combine
import SwiftUI

public class SVGGroup: SVGNode, ObservableObject {

    @Published public var contents: [SVGNode] = []

    public init(
        contents: [SVGNode], transform: CGAffineTransform = .identity,
        opaque: Bool = true, opacity: Double = 1, clip: SVGUserSpaceNode? = nil,
        mask: SVGNode? = nil
    ) {
        super.init(
            transform: transform, opaque: opaque, opacity: opacity, clip: clip,
            mask: mask)
        self.contents = contents
    }

    override public func bounds() -> CGRect {
        for node in contents {
            print("(dg: \(node.id) bounds) \(node.bounds())")
        }
        return contents.map { $0.bounds() }.reduce(
            contents.first?.bounds() ?? CGRect.zero
        ) { $0.union($1) }
    }

    override public func getNode(byId id: String) -> SVGNode? {
        if let node = super.getNode(byId: id) {
            return node
        }
        for node in contents {
            if let node = node.getNode(byId: id) {
                return node
            }
        }
        return .none
    }

    override func serialize(_ serializer: Serializer) {
        super.serialize(serializer)
        serializer.add("contents", contents)
    }

    public func contentView() -> some View {
        SVGGroupView(model: self)
    }
}

struct SVGGroupView: View {

    @ObservedObject var model: SVGGroup

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<model.contents.count, id: \.self) { i in
                    if i <= model.contents.count - 1 {
                        model.contents[i].toSwiftUI()
                            .transformEffect(getTransform(targetSize: proxy.size, size: proxy.size))
                            // .frame(width: proxy.size.width, height: proxy.size.height)
                            .onAppear() {
//                                print("SVGGroupView: id \(model.id); proxy \(proxy.size); transform: \(model.transform)")
                            }
                    }
                }
            }
            .compositingGroup() // so that all the following attributes are applied to the group as a whole
            .applyNodeAttributes(model: model)
        }
    }
    
    private func getTransform(targetSize: CGSize, size: CGSize)
        -> CGAffineTransform
    {
        let preserveAspectRatio = SVGPreserveAspectRatio(scaling: .meet, xAlign: .min, yAlign: .min)
        let transform = preserveAspectRatio.layout(size: targetSize, into: size)
        // move to (0, 0)
        return transform// .translatedBy(x: -viewBox.minX, y: -viewBox.minY)
    }
}

