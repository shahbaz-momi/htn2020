import Foundation

class Prelaunch {
    
    let projectId: String
    let commitId: String
    let file: String
    
    init(projectId: String, commitId: String, file: String) {
        self.projectId = projectId
        self.commitId = commitId
        self.file = file
    }
    
}

class DataManager {
    
    // MARK: - Properties
    
    static let shared = DataManager(projects: [])
    
    static var prelaunch: Prelaunch? = nil
    
    // MARK: -
    
    var projects: [Project]
    
    // Initialization
    
    private init(projects: [Project]) {
        self.projects = projects
    }
    
}
