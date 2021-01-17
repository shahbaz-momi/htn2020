import Foundation

class Commit: Codable {
    var id: String
    var message: String
    var tags: [Tag]
    var parentId: String?
    var branchingName: String?
    var author: String
    var files: [String]
    var comments: [String]

    
    init(id: String, message: String, tags: [Tag], files: [String], comments: [String], parentId: String?, branchingName: String, author: String){
        self.id = id
        self.message = message
        self.tags = tags
        self.files = files
        self.comments = comments
        self.parentId = parentId
        self.branchingName = branchingName
        self.author = author
    }
}
