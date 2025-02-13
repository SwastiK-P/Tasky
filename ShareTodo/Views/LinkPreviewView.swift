import UIKit
import LinkPresentation

class LinkPreviewView: UIView {
    private var linkView: LPLinkView?
    private var url: URL?
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        clipsToBounds = true
        
        addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func loadPreview(for urlString: String) {
        guard let url = URL(string: urlString) else { return }
        self.url = url
        
        loadingIndicator.startAnimating()
        
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { [weak self] metadata, error in
            DispatchQueue.main.async {
                guard let self = self, error == nil, let metadata = metadata else {
                    self?.loadingIndicator.stopAnimating()
                    return
                }
                
                self.linkView?.removeFromSuperview()
                let linkView = LPLinkView(metadata: metadata)
                linkView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(linkView)
                self.linkView = linkView
                
                NSLayoutConstraint.activate([
                    linkView.topAnchor.constraint(equalTo: self.topAnchor),
                    linkView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    linkView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                    linkView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
                ])
                
                self.loadingIndicator.stopAnimating()
            }
        }
    }
} 