import UIKit
import Kingfisher

final class NftImageViewModel: NftMediaViewModelProtocol {
    static let dynamicHeight: CGFloat = -1.0

    let url: URL

    var identifier: String { url.absoluteString }

    init(url: URL) {
        self.url = url
    }

    func loadMedia(
        on imageView: UIImageView,
        displaySettings: NftMediaDisplaySettings,
        completion: ((Bool, Error?) -> Void)?
    ) {
        let targetSize = displaySettings.targetSize
        let cornerRadius = displaySettings.cornerRadius
        let animated = displaySettings.animated

        var compoundProcessor: ImageProcessor = SVGImageProcessor()

        let brokenImageClosure: (KFCrossPlatformImage) -> Bool = { image in image.cgImage != nil }

        if let targetSize = targetSize {
            let scaleProcessor: ImageProcessor

            if targetSize.height == Self.dynamicHeight {
                scaleProcessor = WidthScaleFitProcessor(preferredWidth: targetSize.width, maxHeight: nil)
            } else if displaySettings.isAspectFit {
                scaleProcessor = ResizingImageProcessor(referenceSize: targetSize, mode: .aspectFit)
            } else {
                let resizeProcessor = ResizingImageProcessor(referenceSize: targetSize, mode: .aspectFill)
                let cropProcessor = CroppingImageProcessor(size: targetSize)

                scaleProcessor = resizeProcessor |> cropProcessor
            }

            let filterProcessor = FilterImageProcessor(proccessor: scaleProcessor, filter: brokenImageClosure)
            compoundProcessor = compoundProcessor.append(another: filterProcessor)
        }

        if let cornerRadius = cornerRadius, cornerRadius > 0 {
            let cornerRadiusProcessor = RoundCornerImageProcessor(cornerRadius: cornerRadius)
            let filterProcessor = FilterImageProcessor(
                proccessor: cornerRadiusProcessor,
                filter: brokenImageClosure
            )

            compoundProcessor = compoundProcessor.append(another: filterProcessor)
        }

        var options: KingfisherOptionsInfo = [
            .processor(compoundProcessor),
            .scaleFactor(UIScreen.main.scale),
            .cacheSerializer(RemoteImageSerializer.shared),
            .cacheOriginalImage,
            .diskCacheExpiration(.days(1))
        ]

        if animated {
            options.append(.transition(.fade(0.25)))
        }

        imageView.kf.setImage(
            with: url,
            options: options,
            completionHandler: { result in
                switch result {
                case let .success(kImage):
                    let isResolved = brokenImageClosure(kImage.image)
                    completion?(isResolved, nil)
                case let .failure(error):
                    if !error.isTaskCancelled {
                        completion?(true, error)
                    }
                }
            }
        )
    }

    func cancel(on imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}
