import Foundation

class Project: Codable {
    var id: String
    var lastEditTime: Int
    var name: String
    var description: String?
    var autoCommit: Bool
    var commits: [Commit]
    
    init(id: String, lastEditTime: Int, name: String, description: String?, autoCommit: Bool, commits: [Commit]){
        self.id = id
        self.lastEditTime = lastEditTime
        self.name = name
        self.description = description
        self.autoCommit = autoCommit
        self.commits = commits
    }

}
