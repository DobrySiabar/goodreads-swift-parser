
import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    var downloadTask: URLSessionDownloadTask?
    
    let applicationDocumentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 114/255, green: 216/255,
                                               blue: 255/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func configure(for searchResult: Books) {
        bookNameLabel.text = searchResult.bookTitle
        
        if searchResult.bookAuthor.isEmpty {
            authorNameLabel.text = "Unknown"
        } else {
            authorNameLabel.text = String(format: "%@", searchResult.bookAuthor)
        }
        artworkImageView.image = UIImage(named: "Placeholder")
        if let smallURL = URL(string: searchResult.artworkSmallURL) {
            downloadTask = artworkImageView.loadImage(url: smallURL)
        }
    }
    
    func configure(for searchResult: Book) {
        bookNameLabel.text = searchResult.title
        
        if let searchResult = searchResult.author {
            authorNameLabel.text = String(format: "%@", searchResult)
        } else {
            authorNameLabel.text = "Unknown"
        }
        if let imageName = searchResult.imageName {
            let filePath = applicationDocumentsDirectory.appendingPathComponent("\(imageName).jpg").path
            if FileManager.default.fileExists(atPath: filePath) {
                artworkImageView.image =  UIImage(contentsOfFile: filePath)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        downloadTask?.cancel()
        downloadTask = nil
    }
  
}
