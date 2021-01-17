import UIKit

class ProjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        
        // set the text from the data model
        cell.textLabel?.text = DataManager.shared.projects[indexPath.row].name
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "commits", sender: indexPath.row)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "commits" {
            let destinationViewController = segue.destination as! CommitsViewController
            destinationViewController.selectedProjectIndex = sender as? Int ?? -1
        } else if segue.identifier == "ar2" {
            let destinationViewController = segue.destination as! ARViewController
            let prelaunch = sender as! Prelaunch
            
            guard let project = DataManager.shared.projects.first(where: { $0.id == prelaunch.projectId }) else { return }
            guard let commit = project.commits.first(where: { $0.id == prelaunch.commitId}) else { return }
            let branch = CommitCalculator.getCommitBranch(project: project, commit: commit)
            
            destinationViewController.selectedCommit = commit
            destinationViewController.selectedProjectIndex = DataManager.shared.projects.firstIndex(where: { $0.id == project.id })!
            destinationViewController.branch = branch
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the table view cell class and its reuse id
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // (optional) include this line if you want to remove the extra empty cell divider lines
        // self.tableView.tableFooterView = UIView()
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        tableView.delegate = self
        tableView.dataSource = self
        
        guard let url = URL(string: "http://cd01adcc7b24.ngrok.io:80/project/get_all") else { return }
        
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            if let response = response {
                print(response)
            }
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    
                    let projs = try decoder.decode([Project].self, from: data)
                    
                    DataManager.shared.projects = projs
                    
                    if let prelaunch = DataManager.prelaunch {
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "ar2", sender: prelaunch)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } catch {
                    print(error)
                }
                
            }
            }.resume()
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
